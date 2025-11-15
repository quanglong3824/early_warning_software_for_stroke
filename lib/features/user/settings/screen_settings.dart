import 'package:flutter/material.dart';

class ScreenSettings extends StatefulWidget {
  const ScreenSettings({super.key});

  @override
  State<ScreenSettings> createState() => _ScreenSettingsState();
}

class _ScreenSettingsState extends State<ScreenSettings> {
  bool darkMode = false;
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
            _sectionTitle('Tài khoản & Bảo mật'),
            _card([
              _tile(icon: Icons.person, label: 'Thông tin cá nhân'),
              _divider(),
              _tile(icon: Icons.lock, label: 'Thay đổi mật khẩu'),
              _divider(),
              _tile(icon: shield_person, label: 'Cài đặt quyền riêng tư'),
              _divider(),
              _tile(icon: Icons.contacts, label: 'Liên kết danh bạ khẩn cấp'),
            ]),

            _sectionTitle('Thông báo'),
            _card([
              _tile(icon: Icons.notifications_active, label: 'Cảnh báo sớm'),
              _divider(),
              _tile(icon: Icons.medication, label: 'Nhắc nhở'),
              _divider(),
              _tile(icon: Icons.vibration, label: 'Âm thanh và rung'),
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
              _tile(icon: Icons.help, label: 'Trợ giúp & Phản hồi'),
              _divider(),
              _tile(icon: Icons.info, label: 'Giới thiệu về SEWS'),
              _divider(),
              _tile(icon: Icons.gavel, label: 'Điều khoản & Chính sách'),
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
                onTap: () {},
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