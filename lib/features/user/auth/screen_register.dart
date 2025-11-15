import 'package:flutter/material.dart';

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
                  borderColor: borderColor,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập họ và tên của bạn',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Email hoặc Số điện thoại',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: borderColor,
                  child: TextField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập email hoặc số điện thoại',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: borderColor,
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscure1,
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
                const SizedBox(height: 16),
                const Text('Xác nhận mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                _InputBox(
                  borderColor: borderColor,
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _confirmController,
                        obscureText: _obscure2,
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
                    onPressed: _agree ? () {} : null,
                    child: const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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