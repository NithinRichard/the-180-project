import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import 'auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final error = await context.read<AuthProvider>().signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "THE 180 PROJECT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.voltGreen,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "HSPU EVOLUTION",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, letterSpacing: 2),
            ),
            const SizedBox(height: 80),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "EMAIL",
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "PASSWORD",
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.voltGreen))
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text("ACCESS DASHBOARD"),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text(
                "CREATE NEW PROFILE",
                style: TextStyle(color: Colors.white24, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
