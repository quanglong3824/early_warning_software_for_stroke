import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenDoctorLogin extends StatefulWidget {
  const ScreenDoctorLogin({super.key});

  @override
  State<ScreenDoctorLogin> createState() => _ScreenDoctorLoginState();
}

class _ScreenDoctorLoginState extends State<ScreenDoctorLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final result = await _authService.loginDoctor(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacementNamed('/doctor/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF10B981);
    const borderColor = Color(0xFFDBDFE6);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medical_services, color: primary, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('DOCTOR PORTAL',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 8),
                const Text('Đăng nhập dành cho Bác sĩ',
                    style: TextStyle(fontSize: 16, color: textSecondary)),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _emailError != null ? Colors.red : borderColor,
                  child: TextField(
                    controller: _emailController,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() => _emailError = _validateEmail(value));
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'doctor@example.com',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                    ),
                  ),
                ),
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(_emailError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('Mật khẩu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _passwordError != null ? Colors.red : borderColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          onChanged: (value) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = _validatePassword(value));
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: '••••••',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(15),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      ),
                    ],
                  ),
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: !_isLoading ? _login : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('← Quay lại đăng nhập người dùng', style: TextStyle(color: textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  const _InputBox({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
