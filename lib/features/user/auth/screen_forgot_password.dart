import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenForgotPassword extends StatefulWidget {
  const ScreenForgotPassword({super.key});

  @override
  State<ScreenForgotPassword> createState() => _ScreenForgotPasswordState();
}

class _ScreenForgotPasswordState extends State<ScreenForgotPassword> {
  final TextEditingController _accountController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!_authService.isValidEmail(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  Future<void> _sendResetEmail() async {
    final error = _validateEmail(_accountController.text);
    if (error != null) {
      setState(() {
        _emailError = error;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    final result = await _authService.forgotPassword(_accountController.text.trim());

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
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
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);
    const borderColor = Color(0xFFDBDFE6);

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
                          'Quên Mật Khẩu',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhập email hoặc số điện thoại liên kết với tài khoản của bạn. Chúng tôi sẽ gửi một liên kết để bạn đặt lại mật khẩu.',
                          style: TextStyle(fontSize: 16, color: textSecondary),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Email / Số điện thoại',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _emailError != null ? Colors.red : borderColor),
                          ),
                          child: TextField(
                            controller: _accountController,
                            onChanged: (value) {
                              if (_emailError != null) {
                                setState(() {
                                  _emailError = _validateEmail(value);
                                });
                              }
                            },
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Nhập email của bạn',
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            ),
                            style: const TextStyle(color: textPrimary, fontSize: 16),
                          ),
                        ),
                        if (_emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              _emailError!,
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
                            onPressed: !_isLoading ? _sendResetEmail : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Gửi Hướng Dẫn',
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