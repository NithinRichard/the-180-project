import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLog {
  final String id;
  final String userId;
  final String userName;
  final int reps;
  final String exercise;
  final int formFeel;
  final DateTime timestamp;
  final String? videoUrl;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reps,
    required this.exercise,
    required this.formFeel,
    required this.timestamp,
    this.videoUrl,
  });

  factory WorkoutLog.fromFirestore(Map<String, dynamic> data, String id) {
    return WorkoutLog(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      reps: data['reps'] ?? 0,
      exercise: data['exercise'] ?? 'Unknown',
      formFeel: data['formFeel'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'reps': reps,
      'exercise': exercise,
      'formFeel': formFeel,
      'timestamp': Timestamp.fromDate(timestamp),
      'videoUrl': videoUrl,
    };
  }
}
