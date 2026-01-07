import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/workout_provider.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (!workoutProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.voltGreen)),
      );
    }
    
    final logs = workoutProvider.logs;
    // Filter logs for the current user
    final userLogs = logs.where((l) => l.userId == user?.uid).toList();
    
    // Calculate stats
    final totalSets = userLogs.length;
    final bestReps = userLogs.isEmpty ? 0 : userLogs.map((l) => l.reps).reduce((a, b) => a > b ? a : b);
    final lastExercise = userLogs.isEmpty ? "NONE" : userLogs.first.exercise;
    final joinedDate = userLogs.isEmpty 
        ? "N/A" 
        : DateFormat('MMM yyyy').format(userLogs.map((l) => l.timestamp).reduce((a, b) => a.isBefore(b) ? a : b));

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
            _buildProfileHeader(user?.email ?? "USER"),
            const SizedBox(height: 40),
            _buildStatRow("CURRENT PHASE", lastExercise.toUpperCase()),
            _buildStatRow("TOTAL SETS", totalSets.toString()),
            _buildStatRow("BEST REP COUNT", bestReps.toString()),
            _buildStatRow("JOINED", joinedDate),
            _buildStatRow("SQUAD ID", workoutProvider.isSoloMode ? "PRIVATE SOLO" : workoutProvider.currentTeamId.toUpperCase()),
            const SizedBox(height: 32),
            
            // Show LEAVE SQUAD button if not in private solo mode
            if (workoutProvider.currentTeamId != user?.uid)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextButton.icon(
                    onPressed: () {
                      workoutProvider.resetToSolo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("🤫 DISCONNECTED. YOU ARE NOW SOLO.")),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      "LEAVE SQUAD / GO SOLO",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      workoutProvider.generateNewSquad();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("🚀 CREW CREATED! SHARE YOUR CODE.")),
                      );
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text("CREATE CREW"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.voltGreen,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinDialog(context, workoutProvider),
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text("JOIN SQUAD"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.voltGreen),
                      foregroundColor: AppTheme.voltGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

  void _showJoinDialog(BuildContext context, WorkoutProvider provider) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        title: const Text("JOIN SQUAD"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "SQUAD CODE",
                hintText: "Enter Crew Code...",
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text(
              "Paste the code shared by your teammates.",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                provider.setTeamId(code);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("🔥 JOINED SQUAD: $code")),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("JOIN"),
          ),
        ],
      ),
    );
  }

  Widget _buildModeHint(String mode, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppTheme.voltGreen,
            child: Text(mode, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
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

  Widget _buildProfileHeader(String email) {
    return Column(
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
            email.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
