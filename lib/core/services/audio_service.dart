import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  DateTime? _lastSpeakTime;
  static const Duration _speakCooldown = Duration(seconds: 4);

  AudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speakCue(String cue) async {
    final now = DateTime.now();
    if (_lastSpeakTime == null || now.difference(_lastSpeakTime!) > _speakCooldown) {
      _lastSpeakTime = now;
      await _tts.speak(cue.toLowerCase());
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
