import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ScreenSettings extends StatefulWidget {
  const ScreenSettings({super.key});

  @override
  State<ScreenSettings> createState() => _ScreenSettingsState();
}

class _ScreenSettingsState extends State<ScreenSettings> {
  bool darkMode = false;
  final _authService = AuthService();
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    var shield_person = Icons.privacy_tip;
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF135BEC),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111318),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Người dùng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF616F89),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionTitle('Tài khoản & Bảo mật'),
            _card([
              ListTile(
                leading: _iconBox(Icons.person),
                title: const Text('Thông tin cá nhân'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/edit-profile');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.lock),
                title: const Text('Thay đổi mật khẩu'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/change-password');
                },
              ),
              _divider(),
              _tile(icon: shield_person, label: 'Cài đặt quyền riêng tư'),
              _divider(),
              _tile(icon: Icons.contacts, label: 'Liên kết danh bạ khẩn cấp'),
            ]),

            _sectionTitle('Thông báo'),
            _card([
              ListTile(
                leading: _iconBox(Icons.notifications),
                title: const Text('Cài đặt thông báo'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/settings/notifications');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.medication),
                title: const Text('Nhắc nhở uống thuốc'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/reminders-list');
                },
              ),
            ]),

            _sectionTitle('Cài đặt chung'),
            _card([
              ListTile(
                leading: _iconBox(Icons.language),
                title: const Text('Ngôn ngữ'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Tiếng Việt', style: TextStyle(color: Colors.black54)),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
                onTap: () {},
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.dark_mode),
                title: const Text('Chế độ nền tối'),
                trailing: Switch(
                  value: darkMode,
                  activeColor: primary,
                  onChanged: (v) => setState(() => darkMode = v),
                ),
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.straighten),
                title: const Text('Đơn vị đo lường'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('mmHg', style: TextStyle(color: Colors.black54)),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
                onTap: () {},
              ),
            ]),

            _sectionTitle('Hỗ trợ & Pháp lý'),
            _card([
              ListTile(
                leading: _iconBox(Icons.help),
                title: const Text('Trợ giúp & Hỗ trợ'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/help-support');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.privacy_tip),
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/privacy-policy');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.gavel),
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/terms-of-service');
                },
              ),
            ]),

            const SizedBox(height: 16),
            _card([
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: _logout,
              ),
            ]),

            const SizedBox(height: 12),
            const Center(
              child: Text('Phiên bản ứng dụng 1.0.0', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF135BEC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF135BEC)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Widget _tile({required IconData icon, required String label}) {
    return ListTile(
      leading: _iconBox(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: () {},
    );
  }
}