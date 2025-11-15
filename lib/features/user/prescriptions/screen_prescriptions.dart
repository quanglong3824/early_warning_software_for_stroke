import 'package:flutter/material.dart';

class ScreenPrescriptions extends StatelessWidget {
  const ScreenPrescriptions({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Đơn thuốc của tôi', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 48,
            child: Row(children: const [
              Icon(Icons.search, color: textMuted),
              SizedBox(width: 6),
              Expanded(child: Text('Tìm theo ngày hoặc bác sĩ', style: TextStyle(color: textMuted))),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), children: const [
            _PrescriptionItem(title: 'Đơn thuốc ngày 25/10/2023', subtitle: 'BS. Nguyễn Văn An - Bệnh viện Trung Ương'),
            SizedBox(height: 8),
            _PrescriptionItem(title: 'Đơn thuốc ngày 15/09/2023', subtitle: 'BS. Trần Thị Bích - Phòng khám An Khang'),
            SizedBox(height: 8),
            _PrescriptionItem(title: 'Đơn thuốc ngày 02/08/2023', subtitle: 'BS. Lê Hoàng Cường - Bệnh viện Quốc Tế'),
          ]),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PrescriptionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PrescriptionItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle), alignment: Alignment.center, child: const Icon(Icons.medication, color: primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF616F89), fontSize: 13)),
        ])),
        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      ]),
    );
  }
}