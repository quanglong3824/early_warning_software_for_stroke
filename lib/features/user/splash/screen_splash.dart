import 'package:flutter/material.dart';
import '../dashboard/screen_dashboard.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  State<ScreenSplash> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<ScreenSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.white;
    const primary = Color(0xFF135BEC);
    const textPrimary = Colors.black;
    const textSecondary = Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/img/SEWS_2D.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SEWS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phát hiện sớm, hành động nhanh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  backgroundColor: const Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}