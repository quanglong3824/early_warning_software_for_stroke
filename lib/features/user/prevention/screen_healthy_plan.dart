import 'package:flutter/material.dart';

class ScreenHealthyPlan extends StatelessWidget {
  const ScreenHealthyPlan({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF13EC5B);
    const textPrimary = Color(0xFF111813);
    const textSecondary = Color(0xFF61896F);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Kế hoạch Sống khỏe', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Text('Hôm nay, 24 Tháng 10', style: TextStyle(color: textSecondary, fontSize: 13)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)]),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                  Text('Tiến độ hôm nay', style: TextStyle(color: textPrimary)),
                  Text('3/6', style: TextStyle(color: textPrimary)),
                ]),
                const SizedBox(height: 8),
                Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFDBE6DF), borderRadius: BorderRadius.circular(8)), child: FractionallySizedBox(widthFactor: 0.5, alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8))))),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: const [
              _ChecklistItem(icon: Icons.directions_walk, label: 'Đi bộ nhanh 30 phút', checked: true),
              SizedBox(height: 8),
              _ChecklistItem(icon: Icons.local_drink, label: 'Ăn đủ 5 phần rau và trái cây', checked: true),
              SizedBox(height: 8),
              _ChecklistItem(icon: Icons.water_drop, label: 'Uống đủ 2 lít nước'),
              SizedBox(height: 8),
              _ChecklistItem(icon: Icons.monitor_heart, label: 'Đo huyết áp tại nhà'),
              SizedBox(height: 8),
              _ChecklistItem(icon: Icons.medication, label: 'Uống thuốc theo toa', checked: true),
              SizedBox(height: 8),
              _ChecklistItem(icon: Icons.self_improvement, label: 'Thiền hoặc thư giãn 10 phút'),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(child: Text('Bạn đang làm rất tốt! Hoàn thành kế hoạch để bảo vệ sức khỏe!', style: TextStyle(color: textSecondary))),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool checked;
  const _ChecklistItem({required this.icon, required this.label, this.checked = false});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF13EC5B);
    const textPrimary = Color(0xFF111813);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)]),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF61896F), size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: textPrimary))),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDBE6DF), width: 2), borderRadius: BorderRadius.circular(6), color: checked ? primary : Colors.transparent),
        ),
      ]),
    );
  }
}