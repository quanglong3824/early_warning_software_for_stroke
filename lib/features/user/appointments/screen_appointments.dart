import 'package:flutter/material.dart';

class ScreenAppointments extends StatelessWidget {
  const ScreenAppointments({super.key});
  
  get padding => null;

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Lịch hẹn của tôi', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: textPrimary))],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: const [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    SizedBox(height: 12),
                    Text('Sắp tới', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    SizedBox(height: 3, child: ColoredBox(color: primary)),
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    SizedBox(height: 12),
                    Text('Đã qua', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
                    SizedBox(height: 13),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _AppointmentCard(
                  icon: Icons.task_alt,
                  iconBg: Color(0xFFE6F4EA),
                  iconColor: Color(0xFF16A34A),
                  title: 'Tái khám với BS. Nguyễn Văn An',
                  subtitle: 'Bệnh viện Trung Ương',
                  time: 'Thứ Ba, 25 Th10, 2024 - 09:30 SA',
                ),
                SizedBox(height: 8),
                _AppointmentCard(
                  icon: Icons.pending_actions,
                  iconBg: Color(0xFFFFF3CD),
                  iconColor: Color(0xFFFFA000),
                  title: 'Khám tổng quát',
                  subtitle: 'Phòng khám Đa khoa Quốc tế',
                  time: 'Thứ Sáu, 28 Th10, 2024 - 02:00 CH',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  const _AppointmentCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), alignment: Alignment.center, child: Icon(icon, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            Text(time, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      ]),
    );
  }
}