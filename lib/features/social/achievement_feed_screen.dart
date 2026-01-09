import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../../core/models/workout_log.dart';

class AchievementFeedScreen extends StatefulWidget {
  const AchievementFeedScreen({super.key});

  @override
  State<AchievementFeedScreen> createState() => _AchievementFeedScreenState();
}

class _AchievementFeedScreenState extends State<AchievementFeedScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final clubLogs = context.watch<WorkoutProvider>().clubLogs;

    if (clubLogs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_outlined, size: 64, color: Colors.white10),
              SizedBox(height: 16),
              Text("NO VERIFIED 180s YET", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: clubLogs.length,
        itemBuilder: (context, index) {
          return _FeedItem(log: clubLogs[index]);
        },
      ),
    );
  }
}

class _FeedItem extends StatefulWidget {
  final WorkoutLog log;
  const _FeedItem({required this.log});

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.log.videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.log.videoUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            _controller.setLooping(true);
            _controller.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized)
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        else
          const Center(child: CircularProgressIndicator(color: AppTheme.voltGreen)),

        // Perfect Line Vector Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: PerfectLinePainter(),
          ),
        ),

        // UI Overlays
        Positioned(
          left: 16,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "@${widget.log.userName.toUpperCase()}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.voltGreen.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _getLevelBadge(widget.log.holdDuration),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "HOLD: ${widget.log.holdDuration}s",
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 180 Badge
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.surfaceGrey,
                radius: 28,
                child: Icon(Icons.verified, color: AppTheme.voltGreen, size: 32),
              ),
              const SizedBox(height: 8),
              const Text("VERIFIED", style: TextStyle(color: AppTheme.voltGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Icon(
                widget.log.likes.isNotEmpty ? Icons.favorite : Icons.favorite_outline, 
                color: widget.log.likes.isNotEmpty ? Colors.red : Colors.white, 
                size: 32
              ),
              const SizedBox(height: 4),
              Text(widget.log.likes.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 24),
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(widget.log.commentCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),

        // Close Button
        Positioned(
          top: 60,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  String _getLevelBadge(int duration) {
    if (duration >= 30) return "PLATINUM 180";
    if (duration >= 15) return "GOLD 180";
    return "SILVER 180";
  }
}

class PerfectLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.voltGreen.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Drawing a symbolic "Perfect Line" that tracks the verticle center
    // In a real implementation, this would use pose coordinates from the video metadata
    final center = Offset(size.width / 2, size.height * 0.5);
    
    // Vertical vector
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.1),
      Offset(size.width / 2, size.height * 0.9),
      paint,
    );

    // Indicator pips for joints
    final pipPaint = Paint()..color = AppTheme.voltGreen;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.2), 4, pipPaint); // Ankle
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.5), 4, pipPaint); // Hip
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.8), 4, pipPaint); // Shoulder
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
