import 'package:flutter/material.dart';

class ScreenAdminLogin extends StatefulWidget {
  const ScreenAdminLogin({super.key});

  @override
  State<ScreenAdminLogin> createState() => _ScreenAdminLoginState();
}

class _ScreenAdminLoginState extends State<ScreenAdminLogin> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  // Hardcoded admin credentials (không dùng Firebase)
  final Map<String, String> _adminAccounts = {
    'admin': 'admin123',
    'test': '123456',
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Check credentials
    if (_adminAccounts.containsKey(username) && _adminAccounts[username] == password) {
      Navigator.of(context).pushReplacementNamed('/admin/test');
    } else {
      _showError('Tên đăng nhập hoặc mật khẩu không đúng');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Colors.deepPurple;
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
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.admin_panel_settings, color: primary, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để truy cập',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textSecondary),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tên đăng nhập',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập tên đăng nhập',
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                          style: const TextStyle(color: textPrimary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mật khẩu',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập mật khẩu',
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                ),
                                style: const TextStyle(color: textPrimary, fontSize: 16),
                                onSubmitted: (_) => _login(),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
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
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tài khoản test:\nadmin / admin123\ntest / 123456',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text(
                    '← Quay lại đăng nhập User',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
