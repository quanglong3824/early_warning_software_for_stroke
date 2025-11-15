import 'package:flutter/material.dart';

class ScreenLogin extends StatefulWidget {
  const ScreenLogin({super.key});

  @override
  State<ScreenLogin> createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

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
                    decoration: const InputDecoration(
                      hintText: 'Nhập email hoặc số điện thoại của bạn',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                  borderColor: borderColor,
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
                  borderColor: borderColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
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
                    onPressed: () {
                      final username = _accountController.text.trim();
                      final password = _passwordController.text;
                      
                      // Check credentials and role
                      if (username == 'user' && password == '123456') {
                        // User role - navigate to user dashboard
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      } else if (username == 'doctor' && password == '123456') {
                        // Doctor role - navigate to doctor dashboard
                        Navigator.of(context).pushReplacementNamed('/doctor/dashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu')),
                        );
                      }
                    },
                    child: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    _SocialCircle(
                      borderColor: borderColor,
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC6u7oCYsrFhjJFqJObXRoblIA9x_pTOb7zImQlKQrlIEJnM2W-6DWtrqMvj43tm8cSqn9R8hunQKEWyp6vRiYVAPULyzD8fG5JrChbHrfLca3qozHuVapBHKB12WRe4ehDBwCe7ECzQURMRa2rYlz04TkX8f43gXqSKmkUOBKeT6OU6K4SQabY1YXOtPvncqqdswaAl1qoaG5OX8NC-hrjiMxnr8RTSdnFUTBKn471IWHbZ9JwfYyemn6Fuzf4QKIGCkkM9VsRZfs',
                        height: 24,
                        width: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _SocialCircle(
                      borderColor: borderColor,
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCFqbbbeG-Zqytz67ktK7y4aH9Z5BcjIMEUIgfXIJMaJPs5pP4puC_z_yp-VtA_Of6dgl5rpduQTUZ40IkQYKAF4AKw0tR5HaLHOCdZULBZH3v3gsOMNtjHZMZEYN36Y2kV2OUOWLjZrcVo9whKzSDGm35Dk257-h3EnAQGuNIRBk0qzsI-lo4VSQK_e5u57fKUPTSLQMMGnhiWDwgN4iqWgFdE2gI7YJhprwjatMgHYFnSuLnXY1hZwOwGPWBwZ30efaNmIf400ho',
                        height: 24,
                        width: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
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