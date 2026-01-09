import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/services/health_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/audio_service.dart';

class RestTimerWidget extends StatefulWidget {
  final VoidCallback onFinished;
  final double hrThreshold;
  final bool smartExtension;

  const RestTimerWidget({
    super.key,
    required this.onFinished,
    this.hrThreshold = 110.0,
    this.smartExtension = true,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  int _secondsRemaining = 90;
  double? _currentHR;
  late Timer _timer;
  late Timer _hrTimer;
  final HealthService _healthService = HealthService();
  final AudioService _audioService = AudioService();
  bool _isRecovered = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startHRPolling();
    HapticService.vibrateSetFinished();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _checkRecovery();
      }
    });
  }

  void _startHRPolling() {
    _hrTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final hr = await _healthService.fetchCurrentHeartRate();
      if (mounted) {
        setState(() => _currentHR = hr);
        if (_secondsRemaining == 0) _checkRecovery();
      }
    });
  }

  void _checkRecovery() {
    if (_secondsRemaining == 0) {
      bool hrOk = _currentHR == null || _currentHR! <= widget.hrThreshold;
      
      if (hrOk && !_isRecovered) {
        setState(() => _isRecovered = true);
        HapticService.vibrateOptimalRecovery();
        _audioService.speakCue("Optimal recovery reached. Ready for next set.");
      } else if (!hrOk && !_isRecovered && widget.smartExtension) {
        // Auto-extend if HR is too high and feature enabled
        setState(() => _secondsRemaining += 30);
        _audioService.speakCue("Heart rate high. Extending rest.");
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _hrTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.voltGreen;
    String statusText = "RECOVERED";

    if (_secondsRemaining > 0) {
      statusColor = Colors.red;
      statusText = "RECOVERING...";
    } else if (!_isRecovered) {
      statusColor = Colors.orange;
      statusText = "STABILIZING HR";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BIO-REST",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (_currentHR != null)
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "${_currentHR!.toInt()} BPM",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _secondsRemaining / 90,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Text(
                _secondsToDisplay(_secondsRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _secondsRemaining += 30);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("+30s"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onFinished,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("SKIP TO SET"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _secondsToDisplay(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
