import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY EVOLUTION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.pop(context); // Go back after signout trigger
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.surfaceGrey,
                child: Icon(Icons.person, size: 60, color: AppTheme.voltGreen),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                user?.email ?? "GUEST ATHLETE",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 48),
            _buildStatRow("CURRENT PHASE", "WALL HOLD (LVL 3)"),
            _buildStatRow("TOTAL SETS", "142"),
            _buildStatRow("BEST REP COUNT", "12"),
            _buildStatRow("JOINED", "JAN 2026"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceGrey,
                side: const BorderSide(color: Colors.white10),
              ),
              child: const Text("EDIT PROFILE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, letterSpacing: 1.5)),
          Text(value, style: const TextStyle(color: AppTheme.voltGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
