import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  State<ScreenSplash> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<ScreenSplash> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Kiểm tra trạng thái tài khoản
      final userId = await _authService.getUserId();
      if (userId != null && !userId.startsWith('guest_')) {
        final userData = await _authService.getUserData(userId);
        
        if (userData != null) {
          // Kiểm tra tài khoản bị xóa hoặc chặn
          if (userData['isDeleted'] == true) {
            await _authService.logout();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tài khoản đã bị xóa. Vui lòng liên hệ quản trị viên.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }
          
          if (userData['isBlocked'] == true) {
            await _authService.logout();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tài khoản đã bị chặn. Vui lòng liên hệ quản trị viên.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }
        }
      }
      
      // User has session and account is active, go to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // No session, go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _clearCacheAndRestart() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      backgroundColor: const Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _clearCacheAndRestart,
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Xóa cache & khởi động lại', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}