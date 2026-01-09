import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();
  bool _isAuthorized = false;

  static final List<HealthDataType> types = [
    HealthDataType.HEART_RATE,
  ];

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
      await Permission.location.request();
    }

    _isAuthorized = await _health.requestAuthorization(types);
    return _isAuthorized;
  }

  Future<double?> fetchCurrentHeartRate() async {
    if (!_isAuthorized) {
      bool granted = await requestPermissions();
      if (!granted) return null;
    }

    try {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 5));
      
      List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
        startTime: earlier,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (dataPoints.isNotEmpty) {
        // Sort by date to get the most recent
        dataPoints.sort((a, b) => b.dateTo.compareTo(a.dateTo));
        return double.tryParse(dataPoints.first.value.toString());
      }
    } catch (e) {
      print("Error fetching heart rate: $e");
    }
    return null;
  }
}
