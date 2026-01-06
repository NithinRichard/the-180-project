import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/workout_provider.dart';
import 'features/social/dashboard_screen.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider(),
          update: (_, auth, workout) =>
              workout!..update(auth.user?.uid, auth.user?.email),
        ),
      ],
      child: const The180Project(),
    ),
  );
}

class The180Project extends StatelessWidget {
  const The180Project({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The 180 Project',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}
