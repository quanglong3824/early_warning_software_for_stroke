import 'package:flutter/material.dart';

class ScreenHealthHistory extends StatelessWidget {
  const ScreenHealthHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Lịch sử Sức khỏe'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard('Huyết áp', '120/80', 'mmHg', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Nhịp tim', '85', 'bpm', Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Lịch sử đo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _HistoryItem('Hôm nay, 08:15', 'HA: 145/92, Nhịp tim: 95', Colors.red),
          const SizedBox(height: 12),
          _HistoryItem('Hôm qua, 20:30', 'HA: 135/88, Nhịp tim: 88', Colors.orange),
          const SizedBox(height: 12),
          _HistoryItem('25/07/2024, 07:45', 'HA: 122/81, Nhịp tim: 76', Colors.green),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;
  const _StatCard(this.title, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text('$value $unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date, data;
  final Color color;
  const _HistoryItem(this.date, this.data, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(data, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}