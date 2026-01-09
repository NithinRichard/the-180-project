import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../workout/workout_timer_screen.dart';
import '../workout/progression_tracker_screen.dart';
import '../auth/auth_provider.dart';
import 'video_vault_screen.dart';
import 'profile_screen.dart';
import 'achievement_feed_screen.dart';
import '../workout/session_summary_dialog.dart';
import '../../shared/widgets/video_player_widget.dart';
import '../workout/shoulder_heatmap.dart';
import '../../core/progression_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastLogId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE 180 PROJECT'),
        leading: IconButton(
          icon: const Icon(Icons.stars, color: AppTheme.voltGreen),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AchievementFeedScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.voltGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProgressionTrackerScreen()),
              );
            },
          ),
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
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.voltGreen));
          }

          // Trigger dynamic metrics update if logs have changed
          final latestLog = provider.logs.isNotEmpty ? provider.logs.first.id : "empty";
          if (latestLog != _lastLogId) {
            _lastLogId = latestLog;
            Future.microtask(() => context.read<ProgressionProvider>().calculateMetricsFromLogs(provider.logs));
          }

          final myLastSet = provider.lastMySet;
          final squadSets = provider.squadLogs;
          final currentUser = context.read<AuthProvider>().user; 
          final myName = currentUser?.email?.split('@').first.toUpperCase() ?? "ME";
          final progression = context.watch<ProgressionProvider>();

          return CustomScrollView(
            slivers: [
              // Gamification Stats Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.black,
                  child: Row(
                    children: [
                      StreakFlame(streak: progression.streakCount, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "${progression.streakCount} DAY STREAK",
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const Spacer(),
                      Text(
                        "${(progression.weeklyVolumeLoad / 60).toStringAsFixed(1)}m WEEKLY TUT",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // My Last Set
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  child: _UserSetCard(
                    title: "$myName'S LAST SET",
                    reps: myLastSet?.reps.toString() ?? "0",
                    exercise: myLastSet?.exercise ?? "NONE YET",
                    timeAgo: _formatTimestamp(myLastSet?.timestamp),
                    videoUrl: myLastSet?.videoUrl,
                    isMe: true,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Text(
                    "SQUAD FEED",
                    style: TextStyle(
                      color: AppTheme.voltGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Squad Members
              if (squadSets.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_off_outlined, size: 48, color: Colors.white10),
                          const SizedBox(height: 16),
                          Text(
                            "NO RECENT ACTIVITY IN\n${provider.currentTeamId.toUpperCase()}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Teams only show work logged AFTER joining.\nTry logging a set together! 🦍",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.voltGreen, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = squadSets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        height: 300,
                        child: _UserSetCard(
                          title: "${log.userName.toUpperCase()}'S LAST SET",
                          reps: log.reps.toString(),
                          exercise: log.exercise,
                          timeAgo: _formatTimestamp(log.timestamp),
                          videoUrl: log.videoUrl,
                          isMe: false,
                        ),
                      );
                    },
                    childCount: squadSets.length,
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
  final String? videoUrl;
  final bool isMe;

  const _UserSetCard({
    required this.title,
    required this.reps,
    required this.exercise,
    required this.timeAgo,
    this.videoUrl,
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
            child: videoUrl != null
                ? SizedBox(
                    height: 200,
                    child: VideoPlayerWidget(videoUrl: videoUrl!),
                  )
                : Column(
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
