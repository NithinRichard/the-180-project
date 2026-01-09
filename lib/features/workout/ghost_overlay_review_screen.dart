import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_theme.dart';

class GhostOverlayReviewScreen extends StatefulWidget {
  final String attemptVideoPath;
  final String? referenceVideoPath;

  const GhostOverlayReviewScreen({
    super.key,
    required this.attemptVideoPath,
    this.referenceVideoPath,
  });

  @override
  State<GhostOverlayReviewScreen> createState() => _GhostOverlayReviewScreenState();
}

class _GhostOverlayReviewScreenState extends State<GhostOverlayReviewScreen> {
  late VideoPlayerController _attemptController;
  VideoPlayerController? _referenceController;
  
  bool _isInitialized = false;
  double _opacity = 0.5;
  int _syncOffsetMs = 0; // Offset for reference video in milliseconds
  bool _isFlipped = false;
  double _scale = 1.0;
  bool _isPlaying = false;
  bool _showVerticalGuide = true;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    _attemptController = _createController(widget.attemptVideoPath);
    
    if (widget.referenceVideoPath != null) {
      _referenceController = _createController(widget.referenceVideoPath!);
    }

    await Future.wait([
      _attemptController.initialize(),
      if (_referenceController != null) _referenceController!.initialize(),
    ]);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _attemptController.setLooping(true);
      _referenceController?.setLooping(true);
    }
  }

  VideoPlayerController _createController(String path) {
    if (path.startsWith('http')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      return VideoPlayerController.file(File(path));
    }
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _attemptController.play();
        _syncAndPlayReference();
      } else {
        _attemptController.pause();
        _referenceController?.pause();
      }
    });
  }

  void _syncAndPlayReference() {
    if (_referenceController == null) return;
    
    // Calculate reference position based on attempt and offset
    final attemptPos = _attemptController.value.position.inMilliseconds;
    final targetRefPos = attemptPos + _syncOffsetMs;
    
    if (targetRefPos >= 0 && targetRefPos < _referenceController!.value.duration.inMilliseconds) {
      _referenceController!.seekTo(Duration(milliseconds: targetRefPos));
      _referenceController!.play();
    } else {
      _referenceController!.pause();
    }
  }

  @override
  void dispose() {
    _attemptController.dispose();
    _referenceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.voltGreen)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("GHOST REVIEW", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Overlay Viewport
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _attemptController.value.aspectRatio,
                child: Stack(
                  children: [
                    // Background: Attempt (Original)
                    VideoPlayer(_attemptController),
                    
                    // Foreground: Ghost (Reference)
                    if (_referenceController != null)
                      Opacity(
                        opacity: _opacity,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(_isFlipped ? -_scale : _scale, _scale, 1.0),
                          child: VideoPlayer(_referenceController!),
                        ),
                      ),

                    // Vertical Alignment Guide
                    if (_showVerticalGuide)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: VerticalGuidePainter(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Controls Area
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Opacity Slider
          _buildControlRow(
            label: "GHOST OPACITY",
            value: "${(_opacity * 100).toInt()}%",
            child: Slider(
              value: _opacity,
              onChanged: (val) => setState(() => _opacity = val),
              activeColor: AppTheme.voltGreen,
              inactiveColor: Colors.white10,
            ),
          ),

          const SizedBox(height: 16),

          // Sync Offset
          _buildControlRow(
            label: "SYNC OFFSET",
            value: "${_syncOffsetMs}ms",
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                  onPressed: () => setState(() => _syncOffsetMs -= 50),
                ),
                const Expanded(child: SizedBox()),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () => setState(() => _syncOffsetMs += 50),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Playback & Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(
                icon: Icons.align_vertical_center,
                label: "GUIDE",
                onPressed: () => setState(() => _showVerticalGuide = !_showVerticalGuide),
                isActive: _showVerticalGuide,
              ),
              _buildIconButton(
                icon: _isFlipped ? Icons.flip : Icons.flip_outlined,
                label: "FLIP",
                onPressed: () => setState(() => _isFlipped = !_isFlipped),
                isActive: _isFlipped,
              ),
              FloatingActionButton.large(
                backgroundColor: AppTheme.voltGreen,
                onPressed: _togglePlayback,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 40),
              ),
              _buildIconButton(
                icon: Icons.zoom_in,
                label: "SCALE",
                onPressed: () {
                  setState(() {
                    _scale = _scale >= 1.5 ? 1.0 : _scale + 0.1;
                  });
                },
                isActive: _scale > 1.0,
              ),
              _buildIconButton(
                icon: Icons.accessibility_new,
                label: "SKEL",
                onPressed: () {
                  setState(() => _showSkeleton = !_showSkeleton);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("SKEL MODE requires post-processing..."), duration: Duration(seconds: 1)),
                  );
                },
                isActive: _showSkeleton,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildControlRow({required String label, required String value, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: AppTheme.voltGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        child,
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required String label, required VoidCallback onPressed, bool isActive = false}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isActive ? AppTheme.voltGreen : Colors.white),
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(color: isActive ? AppTheme.voltGreen : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class VerticalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.voltGreen.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Central vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Subtle grid lines
    final dashPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;
    
    for (int i = 1; i <= 4; i++) {
       double x = (size.width / 5) * i;
       canvas.drawLine(Offset(x, 0), Offset(x, size.height), dashPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
