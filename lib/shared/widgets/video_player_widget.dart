import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.loop = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          if (widget.autoPlay) {
            _controller.play();
          }
          _controller.setLooping(widget.loop);
        }
      }).catchError((e) {
        debugPrint("VideoPlayer Error: $e");
        if (mounted) {
          setState(() {
            _error = true;
          });
        }
      });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initialized = false;
      _error = false;
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: AppTheme.surfaceGrey,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              SizedBox(height: 8),
              Text("COULD NOT LOAD VIDEO", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: AppTheme.surfaceGrey,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.voltGreen),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: AppTheme.voltGreen,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}
