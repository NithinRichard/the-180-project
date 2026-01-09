import 'dart:async';
import 'package:flutter/material.dart';
import '../core/firebase_service.dart';
import '../core/models/workout_log.dart';

class WorkoutProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  List<WorkoutLog> _logs = [];
  List<WorkoutLog> _clubLogs = [];
  String? _currentUserId;
  String? _currentUserName;
  String _currentTeamId = "global";
  StreamSubscription? _logsSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _clubSubscription;
  bool _hasFetchedSavedSquad = false;
  bool _isInitialized = false;

  List<WorkoutLog> get logs => _logs;
  List<WorkoutLog> get clubLogs => _clubLogs;
  String? get currentUserId => _currentUserId;
  String get currentTeamId => _currentTeamId;
  bool get isSoloMode => _currentTeamId == _currentUserId || _currentTeamId == "global";
  bool get isInitialized => _isInitialized;

  WorkoutProvider(this._firebaseService) {
    _initLogs();
  }

  void update(String? userId, String? email, {String? teamId}) async {
    if (userId == null) {
      _isInitialized = true;
      notifyListeners();
      return; 
    }

    bool teamChanged = false;
    if (userId != _currentUserId) {
      debugPrint("WorkoutProvider: First session update for $userId");
      _currentUserId = userId;
      _currentUserName = email?.split('@').first.toUpperCase() ?? "ATHLETE";
      
      // Fetch saved squad from Firestore only once per session
      if (!_hasFetchedSavedSquad) {
        _hasFetchedSavedSquad = true;
        final savedTeamId = await _firebaseService.getTeamId(userId);
        if (savedTeamId != null) {
          debugPrint("WorkoutProvider: Found saved squad in Firestore: $savedTeamId");
          _currentTeamId = savedTeamId;
          teamChanged = true;
        } else {
          debugPrint("WorkoutProvider: First login, saving SOLO profile ($userId)");
          _currentTeamId = userId;
          _firebaseService.updateTeamId(userId, userId);
          teamChanged = true;
        }
      }
      _isInitialized = true;
    }
    
    if (teamId != null && teamId != _currentTeamId) {
      debugPrint("WorkoutProvider: teamId override from update: $teamId");
      _currentTeamId = teamId;
      teamChanged = true;
    }
    
    if (teamChanged) {
      _initLogs();
    }
    notifyListeners();
  }

  void setTeamId(String teamId) {
    debugPrint("WorkoutProvider: setTeamId requested with '$teamId'");
    final trimmedCode = teamId.trim();
    if (trimmedCode.isEmpty) {
      resetToSolo();
      return;
    }
    if (trimmedCode != _currentTeamId) {
      debugPrint("WorkoutProvider: Switching team from $_currentTeamId to $trimmedCode");
      _currentTeamId = trimmedCode;
      
      // Persist to Firestore
      if (_currentUserId != null) {
        _firebaseService.updateTeamId(_currentUserId!, trimmedCode);
      }
      
      _initLogs();
      notifyListeners();
    }
  }

  void generateNewSquad() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = DateTime.now().millisecondsSinceEpoch;
    final newCode = 'SQUAD_${List.generate(5, (index) => chars[(rnd + index) % chars.length]).join()}';
    setTeamId(newCode);
  }

  void resetToSolo() {
    debugPrint("WorkoutProvider: resetToSolo requested");
    if (_currentUserId != null) {
      _currentTeamId = _currentUserId!;
      
      // Persist to Firestore
      _firebaseService.updateTeamId(_currentUserId!, _currentUserId!);
      
      _initLogs();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _membersSubscription?.cancel();
    _clubSubscription?.cancel();
    super.dispose();
  }

  void _initLogs() {
    _logsSubscription?.cancel();
    _membersSubscription?.cancel();

    debugPrint("WorkoutProvider: 📡 Starting Member Sync for Squad: $_currentTeamId");
    
    // 1. Sync the list of members in this squad
    _membersSubscription = _firebaseService.getSquadMemberIds(_currentTeamId).listen((memberIds) {
      debugPrint("WorkoutProvider: 👥 Squad members found: ${memberIds.length}");
      
      // 2. Reactively switch the logs stream whenever membership changes
      _logsSubscription?.cancel();
      _logsSubscription = _firebaseService.getWorkoutLogsByUserIds(memberIds).listen(
        (newLogs) {
          debugPrint("WorkoutProvider: ✅ Sync'd ${newLogs.length} historical/new logs for Squad");
          _logs = newLogs;
          notifyListeners();
        },
        onError: (error) {
          debugPrint("WorkoutProvider: ❌ LOG SYNC ERROR: $error");
          if (error.toString().contains("FAILED_PRECONDITION")) {
            debugPrint("WorkoutProvider: ⚠️ MISSING FIRESTORE INDEX! Filter by [userId] + Sort by [timestamp]");
          }
        },
      );
    }, onError: (error) => debugPrint("WorkoutProvider: ❌ MEMBER SYNC ERROR: $error"));

    // 3. Sync "The 180 Club" logs globally
    _clubSubscription?.cancel();
    _clubSubscription = _firebaseService.get180ClubLogs().listen((newClubLogs) {
      debugPrint("WorkoutProvider: 🌟 Sync'd ${newClubLogs.length} 180 CLUB logs");
      _clubLogs = newClubLogs;
      notifyListeners();
    });
  }

  Future<void> addLog({
    required String reps,
    required String exercise,
    required int formFeel,
    String? videoPath,
    int holdDuration = 0,
  }) async {
    if (_currentUserId == null) return;

    String? videoUrl;
    if (videoPath != null) {
      videoUrl = await _firebaseService.uploadVideo(videoPath, _currentUserId!);
    }

    // Calculate Volume Score based on Intensity Multipliers
    double multiplier = 1.0;
    if (exercise.contains('WALL')) {
      multiplier = 0.7;
    } else if (exercise.contains('HSPU') || exercise.contains('PIKE')) {
      multiplier = 1.5;
    } else if (exercise == 'HSPU' || exercise == 'HANDSTAND') {
      multiplier = 1.0;
    }

    final double volumeScore = holdDuration * multiplier;

    final newLog = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      userName: _currentUserName ?? "ME",
      reps: int.tryParse(reps) ?? 0,
      exercise: exercise,
      formFeel: formFeel,
      timestamp: DateTime.now(),
      videoUrl: videoUrl,
      teamId: _currentTeamId,
      holdDuration: holdDuration,
      volumeScore: volumeScore,
    );

    // Add to local list for immediate UI feedback if Firebase is missing
    _logs.insert(0, newLog);
    notifyListeners();
    
    await _firebaseService.logWorkout(newLog);
  }

  WorkoutLog? get lastMySet {
    try {
      return _logs.firstWhere((log) => log.userId == _currentUserId);
    } catch (_) {
      return null;
    }
  }

  WorkoutLog? getPersonalBestLog(String exercise) {
    try {
      final myLogs = _logs.where((log) => log.userId == _currentUserId && log.exercise == exercise && log.videoUrl != null).toList();
      if (myLogs.isEmpty) return null;
      myLogs.sort((a, b) => b.reps.compareTo(a.reps));
      return myLogs.first;
    } catch (_) {
      return null;
    }
  }

  // Gets the latest set for EACH squad member except me
  List<WorkoutLog> get squadLogs {
    final Map<String, WorkoutLog> latestByMember = {};
    for (var log in _logs) {
      if (log.userId != _currentUserId) {
        if (!latestByMember.containsKey(log.userId)) {
          latestByMember[log.userId] = log;
        }
      }
    }
    return latestByMember.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  WorkoutLog? get lastPartnerSet {
    final members = squadLogs;
    return members.isEmpty ? null : members.first;
  }
}
