import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../../core/progression_provider.dart';
import '../../shared/widgets/video_recorder.dart';
import 'hspu_timer_widget.dart';
import 'achievement_dialog.dart';
import 'rest_timer_widget.dart';
import 'rest_settings_screen.dart';
import '../../core/settings_provider.dart';
import 'ghost_overlay_review_screen.dart';
import 'session_summary_dialog.dart';
import '../../core/models/workout_log.dart';
import 'dart:async';

class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key});

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  bool _isTraining = false;
  XFile? _recordedVideo;
  String _selectedExercise = "PUSHUP";
  final List<String> _exercises = ["PUSHUP", "SQUAT", "PIKE_PUSHUP", "ELEVATED_PIKE", "WALL_HOLD", "WALL_HSPU", "HSPU"];
  
  bool _isResting = false;
  
  bool _enableVideo = false;
  bool _enableAI = false;
  
  int _timerValue = 0;
  int _aiRepCount = 0;
  Timer? _sessionTimer;
  
  final GlobalKey<VideoRecorderWidgetState> _recorderKey = GlobalKey();

  final TextEditingController _repsController = TextEditingController(text: "0");

  void _showNotePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.voltGreen, width: 2),
        ),
        title: const Text("SET COMPLETE", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "REPS",
                hintText: "How many did you get?",
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text("FORM FEEL (1-10)", style: TextStyle(color: AppTheme.voltGreen)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                int score = index + 1;
                return _ScoreButton(
                  score: score,
                  onPressed: () => _saveAndExit(score),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                int score = index + 6;
                return _ScoreButton(
                  score: score,
                  onPressed: () => _saveAndExit(score),
                );
              }),
            ),
            if (_recordedVideo != null) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.compare, color: Colors.black),
                label: const Text("GHOST REVIEW"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.voltGreen.withOpacity(0.8),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  final pbLog = Provider.of<WorkoutProvider>(context, listen: false).getPersonalBestLog(_selectedExercise);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GhostOverlayReviewScreen(
                        attemptVideoPath: _recordedVideo!.path,
                        referenceVideoPath: pbLog?.videoUrl,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndExit(int formFeel) async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final progression = Provider.of<ProgressionProvider>(context, listen: false);

    // Close the "SET COMPLETE" dialog first
    Navigator.pop(context);

    // 1. Calculate Session Stats
    final sessionTUT = _timerValue;
    final finalReps = _enableAI ? _aiRepCount : (int.tryParse(_repsController.text) ?? 0);
    
    // 3. Update Progression Metrics dynamically
    // We pass the current logs + the new local log to ensure the summary is immediate and accurate
    final double intensityMultiplier = _selectedExercise.contains('WALL') ? 0.7 : (_selectedExercise.contains('HSPU') ? 1.5 : 1.0);
    final newLog = WorkoutLog(
      id: "temp",
      userId: workoutProvider.currentUserId ?? "anon",
      userName: "ME",
      reps: finalReps,
      exercise: _selectedExercise,
      formFeel: formFeel,
      timestamp: DateTime.now(),
      teamId: workoutProvider.currentTeamId,
      holdDuration: sessionTUT,
      volumeScore: sessionTUT * intensityMultiplier,
    );

    final List<WorkoutLog> updatedLogs = [
      newLog,
      ...workoutProvider.logs,
    ];
    await progression.calculateMetricsFromLogs(updatedLogs);
    
    // 4. Check mastery and level up
    final result = await progression.checkProgress(newLog);
    
    // 5. Save to Firestore via WorkoutProvider
    await workoutProvider.addLog(
      reps: finalReps.toString(),
      exercise: _selectedExercise,
      formFeel: formFeel,
      holdDuration: sessionTUT,
      videoPath: _enableVideo ? _recordedVideo?.path : null,
    );
    
    // 6. Show Summary & Rewards
    if (mounted) {
      // First show the Heatmap Summary
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SessionSummaryDialog(
          streakCount: progression.streakCount,
          weeklyVolume: progression.weeklyVolumeLoad,
          sessionTUT: sessionTUT,
        ),
      );

      // Then show Achievement if mastered
      if (result.isMastered && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AchievementDialog(level: result.level!),
        );
      }
    }
    
    // Reset session variables and enter rest state
    setState(() {
      _isResting = true;
      _timerValue = 0;
      _aiRepCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  // Exercise Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.voltGreen.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedExercise,
                      dropdownColor: Colors.black,
                      underline: const SizedBox(),
                      style: const TextStyle(color: AppTheme.voltGreen, fontWeight: FontWeight.bold),
                      onChanged: _isTraining ? null : (val) {
                        setState(() => _selectedExercise = val!);
                      },
                      items: _exercises.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),

                  const Text(
                    "AI LIVE",
                    style: TextStyle(
                      color: AppTheme.voltGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white54, size: 24),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RestSettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   VideoRecorderWidget(
                    key: _recorderKey,
                    exerciseType: _selectedExercise,
                    enableVideo: _enableVideo,
                    enableAI: _enableAI,
                    onRepCountChanged: (count) {
                      if (_aiRepCount != count) {
                        Future.microtask(() {
                          if (mounted) setState(() => _aiRepCount = count);
                        });
                      }
                    },
                    onRecordingComplete: (file) {
                      _recordedVideo = file;
                    },
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: HSPUTimerWidget(isRunning: _isTraining),
                    ),
                  ),
                  if (_isResting)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.9),
                        child: Center(
                          child: Consumer<SettingsProvider>(
                            builder: (context, settings, child) => RestTimerWidget(
                              hrThreshold: settings.hrThreshold,
                              smartExtension: settings.smartExtension,
                              onFinished: () {
                                Future.microtask(() {
                                  if (mounted) {
                                    setState(() {
                                      _isResting = false;
                                    });
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!_isTraining) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _OptionToggle(
                          label: "VIDEO",
                          value: _enableVideo,
                          onChanged: (val) => setState(() => _enableVideo = val),
                        ),
                        _OptionToggle(
                          label: "AI REPS",
                          value: _enableAI,
                          onChanged: (val) => setState(() => _enableAI = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                     ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isTraining = true;
                          _timerValue = 0;
                          _aiRepCount = 0;
                        });
                        _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                          if (mounted && _isTraining) {
                            setState(() => _timerValue++);
                          } else {
                            timer.cancel();
                          }
                        });
                        if (_enableVideo) {
                          _recorderKey.currentState?.toggleRecording();
                        }
                      },
                      child: const Text("START SET"),
                    ),
                  ]
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        setState(() => _isTraining = false);
                        _sessionTimer?.cancel();
                        if (_enableVideo) {
                          _recorderKey.currentState?.toggleRecording();
                        }
                        _showNotePopup();
                      },
                      child: const Text("STOP / LOG SET"),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    "TEMPO: 1.5s DOWN | 1.5s UP",
                    style: TextStyle(color: AppTheme.voltGreen, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final int score;
  final VoidCallback onPressed;

  const _ScoreButton({required this.score, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.voltGreen, width: 2),
        ),
        child: Text(
          score.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
class _OptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? AppTheme.voltGreen : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? AppTheme.voltGreen : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
