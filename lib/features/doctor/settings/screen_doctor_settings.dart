import 'package:flutter/material.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import '../../../widgets/doctor_drawer.dart';
import '../../../services/auth_service.dart';

class ScreenDoctorSettings extends StatefulWidget {
  const ScreenDoctorSettings({super.key});

  @override
  State<ScreenDoctorSettings> createState() => _ScreenDoctorSettingsState();
}

class _ScreenDoctorSettingsState extends State<ScreenDoctorSettings> {
  final _authService = AuthService();
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final name = await _authService.getUserName();
    if (mounted) {
      setState(() => _doctorName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const bgLight = Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin cá nhân
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 40, color: primary),
                ),
                const SizedBox(height: 12),
                Text(
                  _doctorName ?? 'Bác sĩ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chuyên khoa Tim mạch',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'BYT-12345',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa hồ sơ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cài đặt tài khoản
          _buildSection('Tài khoản', [
            _buildSettingItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'bs.minh@sews.vn',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.phone,
              title: 'Số điện thoại',
              subtitle: '0987 654 321',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.lock,
              title: 'Đổi mật khẩu',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),

          // Cài đặt lịch làm việc
          _buildSection('Lịch làm việc', [
            _buildSettingItem(
              icon: Icons.calendar_today,
              title: 'Lịch trực',
              subtitle: 'Quản lý ca trực',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.schedule,
              title: 'Giờ làm việc',
              subtitle: '07:00 - 15:00',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.event_busy,
              title: 'Ngày nghỉ',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),

          // Thông báo
          _buildSection('Thông báo', [
            _buildSwitchItem(
              icon: Icons.notifications,
              title: 'Thông báo SOS',
              subtitle: 'Nhận thông báo khẩn cấp',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              icon: Icons.calendar_month,
              title: 'Thông báo lịch hẹn',
              subtitle: 'Nhắc nhở lịch hẹn sắp tới',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              icon: Icons.chat,
              title: 'Thông báo tin nhắn',
              subtitle: 'Tin nhắn mới từ bệnh nhân',
              value: true,
              onChanged: (value) {},
            ),
          ]),
          const SizedBox(height: 16),

          // Bảo mật
          _buildSection('Bảo mật', [
            _buildSwitchItem(
              icon: Icons.fingerprint,
              title: 'Xác thực sinh trắc học',
              subtitle: 'Vân tay hoặc Face ID',
              value: false,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              icon: Icons.lock_clock,
              title: 'Tự động đăng xuất',
              subtitle: 'Sau 30 phút không hoạt động',
              value: true,
              onChanged: (value) {},
            ),
          ]),
          const SizedBox(height: 16),

          // Hỗ trợ
          _buildSection('Hỗ trợ', [
            _buildSettingItem(
              icon: Icons.help,
              title: 'Trung tâm trợ giúp',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'Chính sách bảo mật',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.description,
              title: 'Điều khoản sử dụng',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.info,
              title: 'Về ứng dụng',
              subtitle: 'Phiên bản 1.0.0',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // Đăng xuất
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/doctor/login');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 4),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF135BEC),
      ),
    );
  }
}
