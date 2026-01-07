import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';

class HSPUTimerWidget extends StatefulWidget {
  final bool isRunning;
  const HSPUTimerWidget({super.key, required this.isRunning});

  @override
  State<HSPUTimerWidget> createState() => _HSPUTimerWidgetState();
}

class _HSPUTimerWidgetState extends State<HSPUTimerWidget> {
  int _seconds = 0;
  Timer? _timer;
  
  // Metronome logic (3s total cycle)
  Timer? _metronomeTimer;
  bool _isDownPhase = true;

  @override
  void didUpdateWidget(HSPUTimerWidget oldWidget) {
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _metronomeTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
    
    // Start metronome every 1.5s
    _isDownPhase = true;
    _playMetronomeSound();
    _metronomeTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _isDownPhase = !_isDownPhase;
      _playMetronomeSound();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _metronomeTimer?.cancel();
  }

  void _playMetronomeSound() {
    // Using Haptic feedback and System sounds as per requirement for non-visual cues
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isRunning ? AppTheme.voltGreen : Colors.white24,
              width: 8,
            ),
          ),
          child: Center(
            child: Text(
              _formatTime(_seconds),
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: widget.isRunning ? AppTheme.voltGreen : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (widget.isRunning)
          Text(
            _isDownPhase ? "PHASE: DOWN ↓" : "PHASE: UP ↑",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.voltGreen,
              letterSpacing: 2,
            ),
          )
        else
          const Text(
            "TAP TO READY",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white54,
              letterSpacing: 4,
            ),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
