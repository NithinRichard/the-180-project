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
  final String teamId;
  final int holdDuration; // In seconds
  final double volumeScore; // duration * intensity_multiplier
  final List<String> likes; // User IDs who liked
  final int commentCount;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reps,
    required this.exercise,
    required this.formFeel,
    required this.timestamp,
    required this.teamId,
    this.videoUrl,
    this.holdDuration = 0,
    this.volumeScore = 0.0,
    this.likes = const [],
    this.commentCount = 0,
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
      teamId: data['teamId'] ?? 'global',
      holdDuration: data['holdDuration'] ?? 0,
      volumeScore: (data['volumeScore'] ?? 0.0).toDouble(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
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
      'teamId': teamId,
      'holdDuration': holdDuration,
      'volumeScore': volumeScore,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}
