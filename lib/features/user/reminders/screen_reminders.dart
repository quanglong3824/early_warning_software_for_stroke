import 'package:flutter/material.dart';

class ScreenReminders extends StatefulWidget {
  const ScreenReminders({super.key});

  @override
  State<ScreenReminders> createState() => _ScreenRemindersState();
}

class _ScreenRemindersState extends State<ScreenReminders> {
  final List<ReminderItem> _reminders = [
    ReminderItem('Uống thuốc Metformin', '08:00 - Hàng ngày', Icons.medication, true),
    ReminderItem('Đo huyết áp', '09:00 - Thứ 2, Thứ 6', Icons.monitor_heart, true),
    ReminderItem('Uống thuốc Aspirin', '20:00 - Hàng ngày', Icons.medication, false),
  ];

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Quản lý Nhắc nhở', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Sáng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ReminderCard(
            title: _reminders[0].title,
            time: _reminders[0].time,
            icon: _reminders[0].icon,
            isEnabled: _reminders[0].isEnabled,
            onChanged: (val) => setState(() => _reminders[0].isEnabled = val),
          ),
          const SizedBox(height: 12),
          _ReminderCard(
            title: _reminders[1].title,
            time: _reminders[1].time,
            icon: _reminders[1].icon,
            isEnabled: _reminders[1].isEnabled,
            onChanged: (val) => setState(() => _reminders[1].isEnabled = val),
          ),
          const SizedBox(height: 24),
          const Text('Tối', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ReminderCard(
            title: _reminders[2].title,
            time: _reminders[2].time,
            icon: _reminders[2].icon,
            isEnabled: _reminders[2].isEnabled,
            onChanged: (val) => setState(() => _reminders[2].isEnabled = val),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

class ReminderItem {
  String title;
  String time;
  IconData icon;
  bool isEnabled;

  ReminderItem(this.title, this.time, this.icon, this.isEnabled);
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _ReminderCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF50E3C2),
          ),
        ],
      ),
    );
  }
}