import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenResetPassword extends StatefulWidget {
  final String? code; // oobCode từ email link

  const ScreenResetPassword({super.key, this.code});

  @override
  State<ScreenResetPassword> createState() => _ScreenResetPasswordState();
}

class _ScreenResetPasswordState extends State<ScreenResetPassword> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _newPasswordError = _validateNewPassword(_newPasswordController.text);
      _confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
    });

    return _newPasswordError == null && _confirmPasswordError == null;
  }

  Future<void> _resetPassword() async {
    if (!_validateForm()) return;

    if (widget.code == null || widget.code!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link đặt lại mật khẩu không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.confirmPasswordReset(
      code: widget.code!,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Chuyển về màn hình login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const borderColor = Color(0xFFDBDFE6);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhập mật khẩu mới cho tài khoản của bạn.',
                          style: TextStyle(fontSize: 16, color: textSecondary),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Mật khẩu mới',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _newPasswordError != null ? Colors.red : borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  onChanged: (value) {
                                    if (_newPasswordError != null) {
                                      setState(() {
                                        _newPasswordError = _validateNewPassword(value);
                                      });
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập mật khẩu mới',
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  ),
                                  style: const TextStyle(color: textPrimary, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                icon: Icon(
                                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_newPasswordError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              _newPasswordError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Xác nhận mật khẩu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _confirmPasswordError != null ? Colors.red : borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  onChanged: (value) {
                                    if (_confirmPasswordError != null) {
                                      setState(() {
                                        _confirmPasswordError = _validateConfirmPassword(value);
                                      });
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập lại mật khẩu mới',
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  ),
                                  style: const TextStyle(color: textPrimary, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_confirmPasswordError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              _confirmPasswordError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: !_isLoading ? _resetPassword : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Đặt lại mật khẩu',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
