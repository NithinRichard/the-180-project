import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/models/workout_level.dart';

class AchievementDialog extends StatelessWidget {
  final WorkoutLevel level;

  const AchievementDialog({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceGrey,
          border: Border.all(color: AppTheme.voltGreen, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: AppTheme.voltGreen, size: 80),
            const SizedBox(height: 16),
            const Text(
              "MASTERY ACHIEVED",
              style: TextStyle(
                color: AppTheme.voltGreen,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You have mastered ${level.title}!",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              "NEXT PHASE UNLOCKED",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.voltGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("CONTINUE THE JOURNEY"),
            ),
          ],
        ),
      ),
    );
  }
}
