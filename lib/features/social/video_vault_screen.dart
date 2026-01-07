import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../../shared/widgets/video_player_widget.dart';

class VideoVaultScreen extends StatelessWidget {
  const VideoVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIDEO VAULT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: AppTheme.voltGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompareVideosScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final videoLogs = provider.logs.where((log) => log.videoUrl != null).toList();

          if (videoLogs.isEmpty) {
            return const Center(
              child: Text(
                "NO VIDEO EVIDENCE FOUND.\nRECORD A SET TO START YOUR VAULT.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, letterSpacing: 2),
              ),
            );
          }

          return ListView.builder(
            itemCount: videoLogs.length,
            itemBuilder: (context, index) {
              final log = videoLogs[index];
              return _VideoFeedTile(
                userName: log.userName,
                exercise: log.exercise,
                date: DateFormat('MMM dd, yyyy').format(log.timestamp),
                reps: log.reps.toString(),
                videoUrl: log.videoUrl!,
              );
            },
          );
        },
      ),
    );
  }
}

class _VideoFeedTile extends StatelessWidget {
  final String userName;
  final String exercise;
  final String date;
  final String reps;
  final String videoUrl;

  const _VideoFeedTile({
    required this.userName,
    required this.exercise,
    required this.date,
    required this.reps,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real Video Playback
          VideoPlayerWidget(videoUrl: videoUrl),
          
          // Info Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppTheme.voltGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$reps REPS - $exercise",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Compare Shortcut
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: () {},
              child: const Icon(Icons.add, color: AppTheme.voltGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class CompareVideosScreen extends StatelessWidget {
  const CompareVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPARE MODE'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  "OLD VIDEO\nJULY 2025",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 24),
                ),
              ),
            ),
          ),
          const Divider(color: AppTheme.voltGreen, thickness: 4, height: 4),
          Expanded(
            child: Container(
              color: AppTheme.surfaceGrey,
              child: const Center(
                child: Text(
                  "NEW VIDEO\nJAN 2026",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.voltGreen, fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("EXIT"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("PLAY SYNCED"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
