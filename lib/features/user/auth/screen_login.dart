import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenLogin extends StatefulWidget {
  const ScreenLogin({super.key});

  @override
  State<ScreenLogin> createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  // Error messages
  String? _accountError;
  String? _passwordError;

  final _authService = AuthService();

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validation methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$').hasMatch(phone);
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

  bool _validateForm() {
    setState(() {
      _accountError = _validateAccount(_accountController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    return _accountError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
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

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.loginWithGoogle();

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

  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.loginAsGuest();

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

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Cache'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ cache và đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa cache thành công'),
          backgroundColor: Colors.green,
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.health_and_safety_outlined, color: primary, size: 32),
                ),
                const SizedBox(height: 8),
                const Text('SEWS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 16),
                const Text(
                  'Chào mừng trở lại',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textSecondary),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Email hoặc Số điện thoại',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                _InputBox(
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
                      hintText: 'Nhập email hoặc số điện thoại của bạn',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                  borderColor: _accountError != null ? Colors.red : borderColor,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mật khẩu',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/forgot-password');
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('Quên mật khẩu?',
                          style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w500)),
                    )
                  ],
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
                              setState(() {
                                _passwordError = _validatePassword(value);
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Nhập mật khẩu của bạn',
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                          style: const TextStyle(color: textPrimary, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(child: Divider(color: borderColor)),
                    SizedBox(width: 12),
                    Text('hoặc', style: TextStyle(fontSize: 13, color: textSecondary)),
                    SizedBox(width: 12),
                    Expanded(child: Divider(color: borderColor)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _isLoading ? null : _loginWithGoogle,
                      borderRadius: BorderRadius.circular(24),
                      child: _SocialCircle(
                        borderColor: borderColor,
                        child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuC6u7oCYsrFhjJFqJObXRoblIA9x_pTOb7zImQlKQrlIEJnM2W-6DWtrqMvj43tm8cSqn9R8hunQKEWyp6vRiYVAPULyzD8fG5JrChbHrfLca3qozHuVapBHKB12WRe4ehDBwCe7ECzQURMRa2rYlz04TkX8f43gXqSKmkUOBKeT6OU6K4SQabY1YXOtPvncqqdswaAl1qoaG5OX8NC-hrjiMxnr8RTSdnFUTBKn471IWHbZ9JwfYyemn6Fuzf4QKIGCkkM9VsRZfs',
                          height: 24,
                          width: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _loginAsGuest,
                    icon: const Icon(Icons.person_outline, color: textSecondary),
                    label: const Text('Tiếp tục với tư cách Khách',
                        style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? ',
                        style: TextStyle(color: textPrimary, fontSize: 13)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Đăng ký ngay',
                          style: TextStyle(
                              color: primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/doctor/login');
                      },
                      child: const Text(
                        'Bác sĩ',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: textSecondary, fontSize: 12)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/admin/login');
                      },
                      child: const Text(
                        'Admin',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: textSecondary, fontSize: 12)),
                    TextButton(
                      onPressed: _clearCache,
                      child: const Text(
                        'Xóa Cache',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
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

class _SocialCircle extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  const _SocialCircle({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}