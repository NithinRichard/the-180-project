import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'shoulder_heatmap.dart';

class SessionSummaryDialog extends StatelessWidget {
  final int streakCount;
  final double weeklyVolume;
  final int sessionTUT; // Time Under Tension in seconds

  const SessionSummaryDialog({
    super.key,
    required this.streakCount,
    required this.weeklyVolume,
    required this.sessionTUT,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          border: Border.all(color: AppTheme.voltGreen.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "SESSION COMPLETE",
              style: TextStyle(
                color: AppTheme.voltGreen,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Shoulder Heatmap
            ShoulderHeatmap(weeklyVolume: weeklyVolume),
            
            const SizedBox(height: 32),
            
            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(
                  label: "STREAK",
                  value: "$streakCount DAYS",
                  icon: StreakFlame(streak: streakCount, size: 32),
                ),
                _buildMetric(
                  label: "SESSION TUT",
                  value: "${sessionTUT}s",
                  icon: const Icon(Icons.timer_outlined, color: AppTheme.voltGreen, size: 30),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Threshold Notification
            if (sessionTUT > 0 && sessionTUT < 5)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.voltGreen.withOpacity(0.1),
                  border: Border.all(color: AppTheme.voltGreen.withOpacity(0.3)),
                ),
                child: Text(
                  "YOU ARE ${5 - sessionTUT}s AWAY FROM THE 180 CLUB. RECORD YOUR NEXT SET TO JOIN!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.voltGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.voltGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({required String label, required String value, required Widget icon}) {
    return Column(
      children: [
        icon,
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class StreakFlame extends StatelessWidget {
  final int streak;
  final double size;

  const StreakFlame({super.key, required this.streak, this.size = 24});

  Color _getFlameColor() {
    if (streak >= 30) return const Color(0xFFA020F0); // Purple (Mastery)
    if (streak >= 7) return const Color(0xFFFF8C00); // Orange (Building Heat)
    if (streak >= 3) return const Color(0xFF00BFFF); // Blue (Cold Start)
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFlameColor();
    return Icon(
      Icons.local_fire_department,
      color: color,
      size: size,
      shadows: color != Colors.white24 ? [
        Shadow(color: color.withOpacity(0.5), blurRadius: 10),
      ] : null,
    );
  }
}
