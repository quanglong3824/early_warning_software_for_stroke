import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/health_plan_service.dart';

class ScreenHealthyPlan extends StatefulWidget {
  const ScreenHealthyPlan({super.key});

  @override
  State<ScreenHealthyPlan> createState() => _ScreenHealthyPlanState();
}

class _ScreenHealthyPlanState extends State<ScreenHealthyPlan> {
  final _authService = AuthService();
  final _healthPlanService = HealthPlanService();
  
  String? _userId;
  Map<String, bool> _checklist = {};
  
  final List<Map<String, dynamic>> _defaultItems = [
    {'id': 'walk', 'label': 'Đi bộ nhanh 30 phút', 'icon': Icons.directions_walk},
    {'id': 'eat_veggie', 'label': 'Ăn đủ 5 phần rau và trái cây', 'icon': Icons.local_drink},
    {'id': 'drink_water', 'label': 'Uống đủ 2 lít nước', 'icon': Icons.water_drop},
    {'id': 'bp_check', 'label': 'Đo huyết áp tại nhà', 'icon': Icons.monitor_heart},
    {'id': 'medication', 'label': 'Uống thuốc theo toa', 'icon': Icons.medication},
    {'id': 'relax', 'label': 'Thiền hoặc thư giãn 10 phút', 'icon': Icons.self_improvement},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    setState(() => _userId = userId);
  }

  Future<void> _toggleItem(String itemId, bool? value) async {
    if (_userId == null || value == null) return;
    await _healthPlanService.toggleItem(_userId!, itemId, value);
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF13EC5B);
    const textPrimary = Color(0xFF111813);
    const textSecondary = Color(0xFF61896F);
    
    final today = DateFormat('EEEE, d MMMM', 'vi_VN').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Kế hoạch Sống khỏe', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, bool>>(
              stream: _healthPlanService.getDailyChecklist(_userId!),
              builder: (context, snapshot) {
                final checklist = snapshot.data ?? {};
                final completedCount = _defaultItems.where((item) => checklist[item['id']] == true).length;
                final totalCount = _defaultItems.length;
                final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('Hôm nay, $today', style: const TextStyle(color: textSecondary, fontSize: 13))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)]),
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Tiến độ hôm nay', style: TextStyle(color: textPrimary)),
                            Text('$completedCount/$totalCount', style: const TextStyle(color: textPrimary)),
                          ]),
                          const SizedBox(height: 8),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(color: const Color(0xFFDBE6DF), borderRadius: BorderRadius.circular(8)),
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              alignment: Alignment.centerLeft,
                              child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8))),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _defaultItems.map((item) {
                          final isChecked = checklist[item['id']] == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ChecklistItem(
                              icon: item['icon'],
                              label: item['label'],
                              checked: isChecked,
                              onTap: () => _toggleItem(item['id'], !isChecked),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Center(child: Text('Bạn đang làm rất tốt! Hoàn thành kế hoạch để bảo vệ sức khỏe!', style: TextStyle(color: textSecondary))),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _ChecklistItem({required this.icon, required this.label, this.checked = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF13EC5B);
    const textPrimary = Color(0xFF111813);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)]),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF61896F), size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: textPrimary))),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDBE6DF), width: 2),
              borderRadius: BorderRadius.circular(6),
              color: checked ? primary : Colors.transparent,
            ),
            child: checked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}