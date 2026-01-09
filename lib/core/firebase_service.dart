import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'models/workout_log.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream of users who are members of a specific squad
  Stream<List<String>> getSquadMemberIds(String teamId) {
    return _db
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Stream of logs for a list of user IDs (Independent of teamId tag)
  Stream<List<WorkoutLog>> getWorkoutLogsByUserIds(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value([]);
    
    // Firestore whereIn limit is 10, perfect for Squads/Duos
    // We order by timestamp to get the absolute latest across the whole squad
    return _db
        .collection('logs')
        .where('userId', whereIn: userIds)
        .orderBy('timestamp', descending: true)
        .limit(30) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Legacy: Stream of logs for a specific squad tag
  Stream<List<WorkoutLog>> getWorkoutLogs(String teamId) {
    return _db
        .collection('logs')
        .where('teamId', isEqualTo: teamId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Stream of verified high-performance logs for "The 180 Club"
  Stream<List<WorkoutLog>> get180ClubLogs() {
    return _db
        .collection('logs')
        .where('holdDuration', isGreaterThanOrEqualTo: 5)
        .orderBy('holdDuration', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromFirestore(doc.data(), doc.id))
            .where((log) => log.videoUrl != null) // Ensure video exists
            .toList());
  }

  // Log a new set
  Future<void> logWorkout(WorkoutLog log) async {
    await _db.collection('logs').add(log.toFirestore());
  }

  // Update user's current squad in their profile
  Future<void> updateTeamId(String userId, String teamId) async {
    await _db.collection('users').doc(userId).set({
      'teamId': teamId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user's current squad
  Future<String?> getTeamId(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['teamId'] as String?;
  }

  // Upload video to Firebase Storage
  Future<String?> uploadVideo(String filePath, String userId) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      final ref = _storage.ref().child('videos/$userId/$fileName');
      
      // On Web, filePath is often a Blob URL, so we might need to handle it differently 
      // but for now we follow standard cross-platform XFile usage.
      final uploadTask = ref.putData(await XFile(filePath).readAsBytes());
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading video: $e");
      return null;
    }
  }
}
