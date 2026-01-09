import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/progression_provider.dart';
import '../../core/models/workout_level.dart';
import 'safety_tutorial_screen.dart';
import 'dart:ui';

class ProgressionTrackerScreen extends StatelessWidget {
  const ProgressionTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final levels = progression.levels;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ROAD TO 180'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (progression.isSafetyCertified)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.voltGreen.withOpacity(0.1),
                    border: Border.all(color: AppTheme.voltGreen),
                  ),
                  child: const Text(
                    "CERTIFIED FALLER",
                    style: TextStyle(color: AppTheme.voltGreen, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isLast = index == levels.length - 1;
          final isCompleted = level.status == LevelStatus.completed;
          final isCurrent = level.status == LevelStatus.current;
          final isLocked = level.status == LevelStatus.locked;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Line & Dot
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.voltGreen
                            : isCurrent
                                ? Colors.white
                                : Colors.transparent,
                        border: Border.all(
                          color: isCompleted || isCurrent
                              ? AppTheme.voltGreen
                              : Colors.white24,
                          width: 3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.black)
                          : isLocked 
                              ? const Icon(Icons.lock, size: 12, color: Colors.white24)
                              : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          color: isCompleted ? AppTheme.voltGreen : Colors.white24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LEVEL ${level.id}",
                              style: TextStyle(
                                color: isCompleted || isCurrent
                                    ? AppTheme.voltGreen
                                    : Colors.white24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              level.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isCompleted || isCurrent
                                    ? Colors.white
                                    : Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              level.description,
                              style: TextStyle(
                                color: isCompleted || isCurrent
                                    ? Colors.white70
                                    : Colors.white10,
                                fontSize: 14,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(height: 16),
                              _buildProgressInfo(level, progression.masteryProgress),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.voltGreen),
                                ),
                                child: const Text(
                                  "CURRENT PHASE",
                                  style: TextStyle(
                                    color: AppTheme.voltGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                            if (isCompleted) ...[
                              const SizedBox(height: 8),
                              const Text(
                                "MASTERED",
                                style: TextStyle(
                                  color: AppTheme.voltGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Safety Gate Overlay
                        if (level.isSafetyRequired && !progression.isSafetyCertified && !isLocked)
                          Positioned.fill(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.voltGreen,
                                        foregroundColor: Colors.black,
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SafetyTutorialScreen()),
                                      ),
                                      child: const Text("UNLOCK SAFETY TRAINING"),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressInfo(WorkoutLevel level, int masteryProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "GOAL: ${level.targetDuration != null ? '${level.targetDuration}s' : '${level.targetSets}x${level.targetReps}'}",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              "MASTERY: $masteryProgress/2",
              style: const TextStyle(color: AppTheme.voltGreen, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: masteryProgress / 2,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.voltGreen),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
