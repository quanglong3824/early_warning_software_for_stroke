import 'package:flutter/material.dart';

class ScreenFamily extends StatelessWidget {
  const ScreenFamily({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to family management
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/family-management');
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _OldScreenFamily extends StatelessWidget {
  const _OldScreenFamily({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Gia đình của bạn', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: textPrimary))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MemberCard(
            name: 'Trần Thị Bích',
            role: 'Con gái',
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDfdAR2s2VFbWvOu1EW2nr4HRWaKRK_RbilbSihVa0yEkAIzXcz53ZUCzdn0bEC0l_4dca6drCYSghXijWP6ls5iPLJvFK9ilWZapNyrqxIaCEFMVxkOkRYZhiYS9wxbMgq2VNGlur8MmCQdLQSvNAKtn32jNbYVMcP9u1oKKbUiZO9-rUfBDJQMgpyO6Ggr0mpOWyAezkkQ138tleKH30tJIYHGQ5AuJyWWYZxUTtE-knQltJr_9KP_8uYAJokBvrlRF48bCbPRPM',
            statusLabel: 'Đã kết nối',
            statusColor: Color(0xFF07883B),
            statusBg: Color(0xFFE7F6ED),
          ),
          SizedBox(height: 12),
          _MemberCard(
            name: 'Nguyễn Văn An',
            role: 'Người giám hộ',
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAR0TA-upZOzSW0flr5WZPpbW75-kJLeDzBcbMwrj4I19TG6uNIxX7VDlXSLNta8o4tmEgcsyiKp6Wsk5Fa6baQlblA_XN9UmNhc_lXPU_5zp3gSCtGCM9JHuSi6ZOiAK-_bQQ755UBIURfQl8JMKlVqp6aayAdnBF2wPyHvKjSM2cE2dEjdfSEhOFutbQyHfVL_apMULVPr_ulCzFDbsyYAJunzzxi4gssP3ieUpjGkDH4770OBDxfFLrQLwMlV5rvBEr6OIr4ciY',
            statusLabel: 'Đang chờ',
            statusColor: Color(0xFFFFA000),
            statusBg: Color(0xFFFFF3CD),
          ),
          SizedBox(height: 12),
          _MemberCard(
            name: 'Lê Minh Cường',
            role: 'Bệnh nhân chính (Bạn)',
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCiyBYQJkCMcP-AGyYILZtsM4h3ItH6N-bZ5rL19-K3wcLvjeba1zHHvPghvUXyKYh_7SCA4W8bVRwFrXiEUhnRwGj_hqhrzWtnxJSBZOKKn5hzTYni2W3No_gR9Wo7b7h-69h6m6jtuYffSb7PTWooOvH93631yOr3IEjouBFiQd0IAmpOp-BLYrfnfbUqKW9TOBt-Er6CHZ86MHy8yuzmpDPqRTnrO7gcO9jtvrDptBw-6SWhfIW5-VVTDzAYtYfVD_YEoANDb-4',
            statusLabel: 'Cá nhân',
            statusColor: Color(0xFF374151),
            statusBg: Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String avatarUrl;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  const _MemberCard({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.network(avatarUrl, width: 56, height: 56, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(role, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280))),
      ]),
    );
  }
}