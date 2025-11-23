import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../services/auth_service.dart';

class ScreenProfile extends StatelessWidget {
  const ScreenProfile({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    final appData = Provider.of<AppDataProvider>(context);
    final currentUser = appData.currentUser;

    // Helper to format date
    String formatDate(DateTime? date) {
      if (date == null) return 'Chưa cập nhật';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // Helper to format gender
    String formatGender(String? gender) {
      if (gender == 'male') return 'Nam';
      if (gender == 'female') return 'Nữ';
      if (gender == 'other') return 'Khác';
      return 'Chưa cập nhật';
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Thông tin cá nhân', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage: currentUser?.avatarUrl != null
                      ? NetworkImage(currentUser!.avatarUrl!)
                      : null,
                  child: currentUser?.avatarUrl == null
                      ? const Icon(Icons.person, size: 56)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser?.name ?? 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? '',
                  style: const TextStyle(fontSize: 16, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(icon: Icons.person, label: 'Họ và tên', value: currentUser?.name ?? 'Chưa cập nhật'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.mail, label: 'Email', value: currentUser?.email ?? 'Chưa cập nhật'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone, label: 'Số điện thoại', value: currentUser?.phone ?? 'Chưa cập nhật'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on, label: 'Địa chỉ', value: currentUser?.address ?? 'Chưa cập nhật'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.cake, label: 'Ngày sinh', value: formatDate(currentUser?.dateOfBirth)),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.wc,
              label: 'Giới tính',
              value: formatGender(currentUser?.gender),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/edit-profile');
                },
                child: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _MenuSection(
              title: 'Quản lý',
              items: [
                _MenuItem(
                  icon: Icons.family_restroom,
                  label: 'Người thân',
                  onTap: () => Navigator.pushNamed(context, '/family'),
                ),
                _MenuItem(
                  icon: Icons.calendar_today,
                  label: 'Lịch hẹn',
                  onTap: () => Navigator.pushNamed(context, '/appointments'),
                ),
                _MenuItem(
                  icon: Icons.medication,
                  label: 'Đơn thuốc',
                  onTap: () => Navigator.pushNamed(context, '/prescriptions'),
                ),
                _MenuItem(
                  icon: Icons.notifications,
                  label: 'Nhắc nhở',
                  onTap: () => Navigator.pushNamed(context, '/reminders'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuSection(
              title: 'Cài đặt',
              items: [
                _MenuItem(
                  icon: Icons.settings,
                  label: 'Cài đặt chung',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _MenuItem(
                  icon: Icons.emergency,
                  label: 'Thiết lập SOS',
                  onTap: () => Navigator.pushNamed(context, '/sos'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF135BEC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF135BEC)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16))),
          Text(value, style: const TextStyle(color: Color(0xFF111318), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
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
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF135BEC), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111318),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}