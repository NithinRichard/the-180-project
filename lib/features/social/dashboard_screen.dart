import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../workout/workout_timer_screen.dart';
import '../workout/progression_tracker_screen.dart';
import '../auth/auth_provider.dart';
import 'video_vault_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE 180 PROJECT'),
        leading: IconButton(
          icon: const Icon(Icons.map_outlined, color: AppTheme.voltGreen),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProgressionTrackerScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library_outlined, color: AppTheme.voltGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VideoVaultScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.voltGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final myLastSet = provider.lastMySet;
          final partnerLastSet = provider.lastPartnerSet;

          return Column(
            children: [
              Expanded(
                child: _UserSetCard(
                  title: "MY LAST SET",
                  reps: myLastSet?.reps.toString() ?? "0",
                  exercise: myLastSet?.exercise ?? "N/A",
                  timeAgo: _formatTimestamp(myLastSet?.timestamp),
                  isMe: true,
                ),
              ),
              const Divider(color: AppTheme.voltGreen, thickness: 2, height: 2),
              Expanded(
                child: _UserSetCard(
                  title: "PARTNER'S LAST SET",
                  reps: partnerLastSet?.reps.toString() ?? "0",
                  exercise: partnerLastSet?.exercise ?? "N/A",
                  timeAgo: _formatTimestamp(partnerLastSet?.timestamp),
                  isMe: false,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutTimerScreen()),
              );
            },
            child: const Text("START 180 WORKOUT"),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "Never";
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class _UserSetCard extends StatelessWidget {
  final String title;
  final String reps;
  final String exercise;
  final String timeAgo;
  final bool isMe;

  const _UserSetCard({
    required this.title,
    required this.reps,
    required this.exercise,
    required this.timeAgo,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isMe ? Colors.black : AppTheme.surfaceGrey,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.voltGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Text(
                  reps,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  "REPS",
                  style: TextStyle(
                    color: AppTheme.voltGreen.withOpacity(0.7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.voltGreen, width: 2),
                ),
                child: const Icon(Icons.play_arrow, color: AppTheme.voltGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
