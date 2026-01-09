import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> vibrateSetFinished() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  static Future<void> vibrateOptimalRecovery() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }
  }
}
