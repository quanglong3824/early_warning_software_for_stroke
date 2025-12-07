import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/service_initializer.dart';

/// Optimized splash screen with preloading
/// Requirements: 10.1 - Display main dashboard within 3 seconds
class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  State<ScreenSplash> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<ScreenSplash> {
  final _authService = AuthService();
  final _serviceInitializer = ServiceInitializer();
  
  String _statusMessage = 'Đang khởi tạo...';
  double _progress = 0.0;
  StreamSubscription<InitializationProgress>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckSession();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAndCheckSession() async {
    // Listen to initialization progress
    _progressSubscription = _serviceInitializer.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _statusMessage = progress.message;
          _progress = progress.progress;
        });
      }
    });

    // Start service initialization in parallel with minimum splash time
    final initFuture = _serviceInitializer.initialize();
    final minSplashFuture = Future.delayed(const Duration(milliseconds: 1500));

    // Wait for both critical services and minimum splash time
    await Future.wait([
      _serviceInitializer.waitForCritical(),
      minSplashFuture,
    ]);

    if (!mounted) return;

    // Check session while non-critical services continue loading in background
    await _checkSession();
  }

  Future<void> _checkSession() async {
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
                  // Progress indicator with value
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                          backgroundColor: const Color(0xFFE5E7EB),
                        ),
                        if (_progress > 0)
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary.withOpacity(0.7),
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