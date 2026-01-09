import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  bool _autoStartRest = true;
  bool _smartExtension = true;
  double _hrThreshold = 110.0;

  bool get autoStartRest => _autoStartRest;
  bool get smartExtension => _smartExtension;
  double get hrThreshold => _hrThreshold;

  void updateUserId(String? uid) {
    if (uid != _userId) {
      _userId = uid;
      if (_userId != null) {
        _loadSettings();
      }
    }
  }

  Future<void> _loadSettings() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_userId).collection('settings').doc('rest').get();
      if (doc.exists) {
        final data = doc.data()!;
        _autoStartRest = data['autoStartRest'] ?? true;
        _smartExtension = data['smartExtension'] ?? true;
        _hrThreshold = (data['hrThreshold'] ?? 110.0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading rest settings: $e");
    }
  }

  Future<void> updateSettings({
    bool? autoStartRest,
    bool? smartExtension,
    double? hrThreshold,
  }) async {
    if (autoStartRest != null) _autoStartRest = autoStartRest;
    if (smartExtension != null) _smartExtension = smartExtension;
    if (hrThreshold != null) _hrThreshold = hrThreshold;

    notifyListeners();

    if (_userId != null) {
      try {
        await _firestore.collection('users').doc(_userId).collection('settings').doc('rest').set({
          'autoStartRest': _autoStartRest,
          'smartExtension': _smartExtension,
          'hrThreshold': _hrThreshold,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error saving rest settings: $e");
      }
    }
  }
}
