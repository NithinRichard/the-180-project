import 'package:flutter/material.dart';
import '../core/firebase_service.dart';
import '../core/models/workout_log.dart';

class WorkoutProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<WorkoutLog> _logs = [];
  String? _currentUserId;
  String? _currentUserName;

  List<WorkoutLog> get logs => _logs;

  WorkoutProvider() {
    _initLogs();
  }

  void update(String? userId, String? email) {
    _currentUserId = userId;
    _currentUserName = email?.split('@').first.toUpperCase() ?? "ATHLETE";
    notifyListeners();
  }

  void _initLogs() {
    _firebaseService.getWorkoutLogs().listen((newLogs) {
      _logs = newLogs;
      notifyListeners();
    });
  }

  Future<void> addLog({
    required String reps,
    required String exercise,
    required int formFeel,
  }) async {
    if (_currentUserId == null) return;

    final newLog = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      userName: _currentUserName ?? "ME",
      reps: int.tryParse(reps) ?? 0,
      exercise: exercise,
      formFeel: formFeel,
      timestamp: DateTime.now(),
    );

    // Add to local list for immediate UI feedback if Firebase is missing
    _logs.insert(0, newLog);
    notifyListeners();
    
    await _firebaseService.logWorkout(newLog);
  }

  WorkoutLog? get lastMySet => _logs.firstWhere(
        (log) => log.userId == _currentUserId,
        orElse: () => _placeholderLog('ME'),
      );

  WorkoutLog? get lastPartnerSet => _logs.firstWhere(
        (log) => log.userId != _currentUserId,
        orElse: () => _placeholderLog('PARTNER'),
      );

  WorkoutLog _placeholderLog(String name) {
    return WorkoutLog(
      id: '0',
      userId: name == 'ME' ? 'user_1' : 'user_2',
      userName: name,
      reps: 0,
      exercise: 'N/A',
      formFeel: 0,
      timestamp: DateTime.now(),
    );
  }
}
