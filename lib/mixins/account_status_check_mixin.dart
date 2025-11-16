import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Mixin để kiểm tra trạng thái tài khoản (bị chặn/xóa)
/// Sử dụng trong StatefulWidget để tự động kiểm tra khi màn hình được mở
mixin AccountStatusCheckMixin<T extends StatefulWidget> on State<T> {
  final _authService = AuthService();
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    // Kiểm tra ngay khi màn hình được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccountStatus();
    });
  }

  /// Kiểm tra trạng thái tài khoản
  Future<void> _checkAccountStatus() async {
    if (_isCheckingStatus) return;
    _isCheckingStatus = true;

    final result = await _authService.checkAccountStatus();

    if (!mounted) return;

    if (result['isValid'] != true) {
      // Tài khoản không hợp lệ, hiển thị thông báo và chuyển về login
      final message = result['message'] ?? 'Tài khoản không hợp lệ';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      // Chuyển về màn hình login tương ứng
      final session = await _authService.getUserSession();
      final role = session['userRole'];
      
      String loginRoute = '/login';
      if (role == 'doctor') {
        loginRoute = '/doctor/login';
      } else if (role == 'admin') {
        loginRoute = '/admin/login';
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        loginRoute,
        (route) => false,
      );
    }

    _isCheckingStatus = false;
  }

  /// Gọi method này khi cần kiểm tra lại (ví dụ: sau khi resume app)
  Future<void> recheckAccountStatus() async {
    await _checkAccountStatus();
  }
}
