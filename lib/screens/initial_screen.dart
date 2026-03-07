import 'package:flutter/material.dart';
import 'package:claverit/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'registration_step1_screen.dart';
import '../models/registration_data.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _showSplash = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenSplash') ?? false;
    setState(() {
      _showSplash = !seen;
      _ready = true;
    });
  }

  Future<void> _onSplashFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSplash', true);
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showSplash) {
      return SplashScreen(onFinish: _onSplashFinish);
    }

    // After splash (or if already seen) show normal auth-based entry
    return FutureBuilder<String?>(
      future: AuthService.getAuthToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return const DashboardScreen();
        }
        return const PhoneInputScreen();
      },
    );
  }
}
