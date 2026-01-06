import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models/workout_log.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream of logs for the dual dashboard
  Stream<List<WorkoutLog>> getWorkoutLogs() {
    return _db
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Log a new set
  Future<void> logWorkout(WorkoutLog log) async {
    await _db.collection('logs').add(log.toFirestore());
  }

  // Upload video placeholder logic
  Future<String> uploadVideo(String filePath, String userId) async {
    return "https://example.com/video_url.mp4";
  }
}
