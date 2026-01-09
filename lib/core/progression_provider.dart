import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/workout_level.dart';
import 'models/workout_log.dart';
import 'firebase_service.dart';

class ProgressionProvider with ChangeNotifier {
  FirebaseService? _firebaseService;
  String? _userId;

  int _currentLevelId = 1;
  int _masteryProgress = 0; // 0 to 2 (needs 2 successful workouts)
  bool _isSafetyCertified = false;
  int _streakCount = 0;
  double _weeklyVolumeLoad = 0.0;
  
  final List<WorkoutLevel> _levels = [
    WorkoutLevel(
      id: 1,
      title: "Normal Push Up",
      description: "Foundational horizontal pushing strength.",
      exercise: "PUSHUP",
      targetReps: 15,
      targetSets: 3,
    ),
    WorkoutLevel(
      id: 2,
      title: "Pike Push Up",
      description: "Building shoulder overhead pushing strength.",
      exercise: "PIKE_PUSHUP",
      targetReps: 12,
      targetSets: 3,
    ),
    WorkoutLevel(
      id: 3,
      title: "Elevated Pike",
      description: "Adding more weight by elevating feet.",
      exercise: "ELEVATED_PIKE",
      targetReps: 10,
      targetSets: 3,
    ),
    WorkoutLevel(
      id: 4,
      title: "Wall Hold",
      description: "Getting comfortable being upside down.",
      exercise: "WALL_HOLD",
      targetDuration: 60,
      isSafetyRequired: true,
    ),
    WorkoutLevel(
      id: 5,
      title: "Wall HSPU",
      description: "The primary strength builder for freestanding.",
      exercise: "WALL_HSPU",
      targetReps: 8,
      targetSets: 3,
      isSafetyRequired: true,
    ),
    WorkoutLevel(
      id: 6,
      title: "Freestanding",
      description: "The ultimate goal. 180 degrees of power.",
      exercise: "HSPU",
      targetDuration: 10,
      isSafetyRequired: true,
    ),
  ];

  ProgressionProvider();

  void updateUserId(String? uid) {
    if (uid != _userId) {
      _userId = uid;
      if (_userId != null) {
        _loadProgress();
      }
    }
  }

  int get currentLevelId => _currentLevelId;
  int get masteryProgress => _masteryProgress;
  bool get isSafetyCertified => _isSafetyCertified;
  int get streakCount => _streakCount;
  double get weeklyVolumeLoad => _weeklyVolumeLoad;

  List<WorkoutLevel> get levels => _levels.map((l) {
    if (l.id < _currentLevelId) return l.copyWith(status: LevelStatus.completed);
    
    // Safety Lock Logic
    if (l.isSafetyRequired && !_isSafetyCertified && l.id >= _currentLevelId) {
       // We only show it as current if it's the current level, but the UI will handle the overlay
       if (l.id == _currentLevelId) return l.copyWith(status: LevelStatus.current);
       return l.copyWith(status: LevelStatus.locked);
    }

    if (l.id == _currentLevelId) return l.copyWith(status: LevelStatus.current);
    return l.copyWith(status: LevelStatus.locked);
  }).toList();

  WorkoutLevel get currentLevel => _levels.firstWhere((l) => l.id == _currentLevelId);

  Future<void> _loadProgress() async {
    if (_userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentLevelId = data['currentLevel'] ?? 1;
        _masteryProgress = data['masteryProgress'] ?? 0;
        _isSafetyCertified = data['isSafetyCertified'] ?? false;
        _streakCount = data['streakCount'] ?? 0;
        _weeklyVolumeLoad = (data['weeklyVolumeLoad'] ?? 0.0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading progression: $e");
    }
  }

  Future<void> _saveProgress() async {
    if (_userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'currentLevel': _currentLevelId,
        'masteryProgress': _masteryProgress,
        'isSafetyCertified': _isSafetyCertified,
        'streakCount': _streakCount,
        'weeklyVolumeLoad': _weeklyVolumeLoad,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving progression: $e");
    }
  }

  /// Checks if the latest workout log contributes to mastery
  Future<MasteryResult> checkProgress(WorkoutLog log) async {
    final level = currentLevel;
    if (log.exercise.toUpperCase() != level.exercise.toUpperCase()) {
      return MasteryResult(isMastered: false);
    }

    bool success = false;
    if (level.targetDuration != null) {
      if (log.reps >= level.targetDuration!) {
        success = true;
      }
    } else {
      if (log.reps >= level.targetReps) {
        success = true;
      }
    }

    if (success) {
      _masteryProgress++;
      if (_masteryProgress >= 2) {
        final masteredLevel = level;
        _levelUp();
        await _saveProgress();
        notifyListeners();
        return MasteryResult(isMastered: true, level: masteredLevel);
      }
      await _saveProgress();
      notifyListeners();
    }
    return MasteryResult(isMastered: false);
  }

  void _levelUp() {
    if (_currentLevelId < _levels.length) {
      _currentLevelId++;
      _masteryProgress = 0;
    }
  }

  Future<void> completeSafetyTraining() async {
    _isSafetyCertified = true;
    await _saveProgress();
    notifyListeners();
  }

  Future<void> updateMetrics({int? streak, double? weeklyVolume}) async {
    if (streak != null) _streakCount = streak;
    if (weeklyVolume != null) _weeklyVolumeLoad = weeklyVolume;
    await _saveProgress();
    notifyListeners();
  }

  /// Dynamically calculate streak and volume from the provided logs
  Future<void> calculateMetricsFromLogs(List<WorkoutLog> logs) async {
    if (_userId == null) return;

    final myLogs = logs.where((l) => l.userId == _userId).toList();
    if (myLogs.isEmpty) {
      _streakCount = 0;
      _weeklyVolumeLoad = 0.0;
      notifyListeners();
      return;
    }

    // 1. Calculate Weekly Volume (Last 7 days)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    _weeklyVolumeLoad = myLogs
        .where((l) => l.timestamp.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, l) => sum + l.volumeScore);

    // 2. Calculate Streak
    // Get unique dates of workouts, sorted descending
    final workoutDates = myLogs.map((l) => DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    // If no workout today or yesterday, streak is broken
    if (workoutDates.isEmpty || (workoutDates.first != today && workoutDates.first != yesterday)) {
      streak = 0;
    } else {
      streak = 1;
      for (int i = 0; i < workoutDates.length - 1; i++) {
        if (workoutDates[i].difference(workoutDates[i + 1]).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
    }
    _streakCount = streak;
    
    await _saveProgress();
    notifyListeners();
  }

  void manualOverride(int levelId) {
    _currentLevelId = levelId;
    _masteryProgress = 0;
    _saveProgress();
    notifyListeners();
  }
}

class MasteryResult {
  final bool isMastered;
  final WorkoutLevel? level;

  MasteryResult({required this.isMastered, this.level});
}
