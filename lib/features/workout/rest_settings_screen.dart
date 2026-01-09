import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/settings_provider.dart';

class RestSettingsScreen extends StatelessWidget {
  const RestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "BIO-REST SETTINGS",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.voltGreen.withOpacity(0.3), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("AUTOMATION"),
          _buildToggle(
            context,
            "AUTO-START REST",
            "Begin recovery timer immediately after logging a set.",
            settings.autoStartRest,
            (val) => settings.updateSettings(autoStartRest: val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("BIO-FEEDBACK"),
          _buildToggle(
            context,
            "SMART EXTENSION",
            "Automatically add 30s if Heart Rate is above threshold.",
            settings.smartExtension,
            (val) => settings.updateSettings(smartExtension: val),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("RECOVERY THRESHOLD"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "HEART RATE GOAL",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${settings.hrThreshold.toInt()} BPM",
                      style: const TextStyle(
                        color: AppTheme.voltGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.voltGreen,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: AppTheme.voltGreen,
                    overlayColor: AppTheme.voltGreen.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: settings.hrThreshold,
                    min: 60,
                    max: 160,
                    onChanged: (val) => settings.updateSettings(hrThreshold: val),
                  ),
                ),
                const Text(
                  "Rest will only conclude when HR drops below this point.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.voltGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.voltGreen,
            activeTrackColor: AppTheme.voltGreen.withOpacity(0.3),
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
