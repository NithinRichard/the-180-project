import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ShoulderHeatmap extends StatefulWidget {
  final double weeklyVolume; // Total volume score for the week

  const ShoulderHeatmap({super.key, required this.weeklyVolume});

  @override
  State<ShoulderHeatmap> createState() => _ShoulderHeatmapState();
}

class _ShoulderHeatmapState extends State<ShoulderHeatmap> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getHeatmapColor() {
    final v = widget.weeklyVolume;
    if (v < 300) return const Color(0xFF2D2D2D); // Recovery (0-5 mins)
    if (v < 1200) return const Color(0xFF00FFCC); // Active (5-20 mins)
    if (v < 3600) return const Color(0xFFFFD700); // Peak (20-60 mins)
    return const Color(0xFFFF4500); // Overload (60+ mins)
  }

  String _getStatusText() {
    final v = widget.weeklyVolume;
    if (v < 300) return "DORMANT / RECOVERY";
    if (v < 1200) return "ACTIVE LOAD";
    if (v < 3600) return "PEAK OUTPUT";
    return "OVERLOAD WARNING";
  }

  @override
  Widget build(BuildContext context) {
    final color = _getHeatmapColor();
    final isOverload = widget.weeklyVolume >= 3600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 240),
              painter: TorsoHeatmapPainter(
                baseColor: color,
                intensity: isOverload ? (0.6 + 0.4 * _pulseController.value) : 1.0,
                glowSize: isOverload ? (1.2 + 0.3 * _pulseController.value) : 1.0,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          _getStatusText(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        Text(
          "${(widget.weeklyVolume / 60).toStringAsFixed(1)} MIN TUT THIS WEEK",
          style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
        ),
      ],
    );
  }
}

class TorsoHeatmapPainter extends CustomPainter {
  final Color baseColor;
  final double intensity;
  final double glowSize;

  TorsoHeatmapPainter({
    required this.baseColor,
    this.intensity = 1.0,
    this.glowSize = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // 1. Draw Torso Silhouette (simplified)
    final torsoPath = Path();
    // Neck
    torsoPath.moveTo(size.width * 0.4, 0);
    torsoPath.lineTo(size.width * 0.6, 0);
    // Traps / Shoulders
    torsoPath.lineTo(size.width * 0.9, size.height * 0.2);
    // Upper Arm
    torsoPath.lineTo(size.width, size.height * 0.4);
    torsoPath.lineTo(size.width * 0.8, size.height * 0.45);
    // Torso side
    torsoPath.lineTo(size.width * 0.75, size.height);
    torsoPath.lineTo(size.width * 0.25, size.height);
    // Torso side left
    torsoPath.lineTo(size.width * 0.2, size.height * 0.45);
    torsoPath.lineTo(0, size.height * 0.4);
    // Shoulders left
    torsoPath.lineTo(size.width * 0.1, size.height * 0.2);
    torsoPath.close();

    canvas.drawPath(torsoPath, paint);

    // 2. Draw Heat Glows (Shoulders and Scapula area)
    if (baseColor != const Color(0xFF2D2D2D)) {
      _drawGlow(canvas, Offset(size.width * 0.8, size.height * 0.25), 40 * glowSize); // Right Shoulder
      _drawGlow(canvas, Offset(size.width * 0.2, size.height * 0.25), 40 * glowSize); // Left Shoulder
      _drawGlow(canvas, Offset(size.width * 0.5, size.height * 0.35), 30 * glowSize); // Mid/Lower Trap
    }

    // 3. Draw Outline
    final outlinePaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(torsoPath, outlinePaint);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final gradient = RadialGradient(
      colors: [
        baseColor.withOpacity(0.6 * intensity),
        baseColor.withOpacity(0.2 * intensity),
        Colors.transparent,
      ],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
