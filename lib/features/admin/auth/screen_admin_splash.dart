import 'package:flutter/material.dart';
import '../../../services/admin_test_account.dart';

class ScreenAdminSplash extends StatefulWidget {
  const ScreenAdminSplash({super.key});

  @override
  State<ScreenAdminSplash> createState() => _ScreenAdminSplashState();
}

class _ScreenAdminSplashState extends State<ScreenAdminSplash> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Tạo tài khoản admin test nếu chưa có
    await AdminTestAccount.createAdminAccount();
    
    // Chờ 2 giây rồi chuyển sang màn hình login
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);
    
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.admin_panel_settings, color: primary, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'ADMIN PANEL',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SEWS Healthcare System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
