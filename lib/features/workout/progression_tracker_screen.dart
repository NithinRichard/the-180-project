import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ProgressionTrackerScreen extends StatelessWidget {
  const ProgressionTrackerScreen({super.key});

  final List<ProgressionStep> steps = const [
    ProgressionStep(
      title: "Pike Push Up",
      description: "Building shoulder overhead pushing strength.",
      level: 1,
      isCompleted: true,
    ),
    ProgressionStep(
      title: "Elevated Pike",
      description: "Adding more weight by elevating feet.",
      level: 2,
      isCompleted: true,
    ),
    ProgressionStep(
      title: "Wall Hold",
      description: "Getting comfortable being upside down.",
      level: 3,
      isCurrent: true,
    ),
    ProgressionStep(
      title: "Wall HSPU",
      description: "The primary strength builder for freestanding.",
      level: 4,
    ),
    ProgressionStep(
      title: "Freestanding",
      description: "The ultimate goal. 180 degrees of power.",
      level: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROAD TO 180'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

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
                        color: step.isCompleted
                            ? AppTheme.voltGreen
                            : step.isCurrent
                                ? Colors.white
                                : Colors.transparent,
                        border: Border.all(
                          color: step.isCompleted || step.isCurrent
                              ? AppTheme.voltGreen
                              : Colors.white24,
                          width: 3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: step.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.black)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          color: step.isCompleted ? AppTheme.voltGreen : Colors.white24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LEVEL ${step.level}",
                          style: TextStyle(
                            color: step.isCompleted || step.isCurrent
                                ? AppTheme.voltGreen
                                : Colors.white24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: step.isCompleted || step.isCurrent
                                ? Colors.white
                                : Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.description,
                          style: TextStyle(
                            color: step.isCompleted || step.isCurrent
                                ? Colors.white70
                                : Colors.white10,
                            fontSize: 16,
                          ),
                        ),
                        if (step.isCurrent) ...[
                          const SizedBox(height: 16),
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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
}

class ProgressionStep {
  final String title;
  final String description;
  final int level;
  final bool isCompleted;
  final bool isCurrent;

  const ProgressionStep({
    required this.title,
    required this.description,
    required this.level,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}
