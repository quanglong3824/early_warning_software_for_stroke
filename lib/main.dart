import 'dart:async';
import 'package:flutter/material.dart';
import 'app/app_router.dart';
import 'features/main/main_page.dart';

void main() {
  runApp(const EarlyWarningApp());
}

class EarlyWarningApp extends StatelessWidget {
  const EarlyWarningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Early Warning Software for Stroke',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.main: (context) => const MainPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 10), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/img/SEWS_2D.png',
              width: 280,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}