import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenRegister extends StatefulWidget {
  const ScreenRegister({super.key});

  @override
  State<ScreenRegister> createState() => _ScreenRegisterState();
}

class _ScreenRegisterState extends State<ScreenRegister> {
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;
  bool _isLoading = false;

  // Error messages
  String? _nameError;
  String? _accountError;
  String? _passwordError;
  String? _confirmError;

  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Validation methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$').hasMatch(phone);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validateAccount(String value) {
    if (value.trim().isEmpty) {
      return 'Vui lòng nhập email hoặc số điện thoại';
    }
    if (!_isValidEmail(value) && !_isValidPhone(value)) {
      return 'Email hoặc số điện thoại không hợp lệ';
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

  String? _validateConfirmPassword(String value, String password) {
    if (value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _accountError = _validateAccount(_accountController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmError = _validateConfirmPassword(_confirmController.text, _passwordController.text);
    });

    return _nameError == null &&
        _accountError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _register() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      name: _nameController.text.trim(),
      account: _accountController.text.trim(),
      password: _passwordController.text,
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
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/dashboard');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.verified_outlined, color: primary, size: 40),
                      ),
                      const SizedBox(height: 8),
                      const Text('SEWS',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                      const Text('Early Warning Software',
                          style: TextStyle(fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tạo tài khoản mới',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 6),
                const Text('Bắt đầu theo dõi và bảo vệ sức khỏe của bạn.',
                    style: TextStyle(fontSize: 16, color: textSecondary)),
                const SizedBox(height: 24),
                const Text('Họ và tên',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _nameError != null ? Colors.red : borderColor,
                  child: TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      if (_nameError != null) {
                        setState(() {
                          _nameError = _validateName(value);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Nhập họ và tên của bạn',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                ),
                if (_nameError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _nameError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Email hoặc Số điện thoại',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _accountError != null ? Colors.red : borderColor,
                  child: TextField(
                    controller: _accountController,
                    onChanged: (value) {
                      if (_accountError != null) {
                        setState(() {
                          _accountError = _validateAccount(value);
                        });
                      }
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Nhập email hoặc số điện thoại',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                ),
                if (_accountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _accountError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _passwordError != null ? Colors.red : borderColor,
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscure1,
                        onChanged: (value) {
                          if (_passwordError != null) {
                            setState(() {
                              _passwordError = _validatePassword(value);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Nhập mật khẩu',
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                        style: const TextStyle(color: textPrimary, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off, color: textSecondary),
                    )
                  ]),
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Xác nhận mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: _confirmError != null ? Colors.red : borderColor,
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _confirmController,
                        obscureText: _obscure2,
                        onChanged: (value) {
                          if (_confirmError != null) {
                            setState(() {
                              _confirmError = _validateConfirmPassword(value, _passwordController.text);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Nhập lại mật khẩu',
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                        style: const TextStyle(color: textPrimary, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: textSecondary),
                    )
                  ]),
                ),
                if (_confirmError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _confirmError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      side: const BorderSide(color: borderColor),
                      activeColor: primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: textSecondary),
                          children: [
                            TextSpan(text: 'Tôi đồng ý với '),
                            TextSpan(text: 'Điều khoản Dịch vụ', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                            TextSpan(text: ' và '),
                            TextSpan(text: 'Chính sách Bảo mật', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    )
                  ],
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
                    onPressed: (_agree && !_isLoading) ? _register : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? ', style: TextStyle(color: textSecondary, fontSize: 13)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Đăng nhập ngay',
                          style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
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