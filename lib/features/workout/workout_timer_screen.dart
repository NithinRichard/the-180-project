import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../../shared/widgets/video_recorder.dart';
import 'hspu_timer_widget.dart';

class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key});

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  bool _isTraining = false;
  XFile? _recordedVideo;
  String _selectedExercise = "SQUAT";
  final List<String> _exercises = ["SQUAT", "PUSHUP", "HSPU"];
  
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
          ],
        ),
      ),
    );
  }

  void _saveAndExit(int formFeel) {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    provider.addLog(
      reps: _repsController.text,
      exercise: _selectedExercise,
      formFeel: formFeel,
      videoPath: _recordedVideo?.path,
    );
    Navigator.pop(context); // Close dialog
    Navigator.pop(context); // Exit timer screen
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!_isTraining)
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _isTraining = true);
                        _recorderKey.currentState?.toggleRecording();
                      },
                      child: const Text("START SET"),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        setState(() => _isTraining = false);
                        _recorderKey.currentState?.toggleRecording();
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
