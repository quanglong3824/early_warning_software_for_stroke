import 'package:flutter/material.dart';

class ScreenAdminAppointments extends StatefulWidget {
  const ScreenAdminAppointments({super.key});

  @override
  State<ScreenAdminAppointments> createState() => _ScreenAdminAppointmentsState();
}

class _ScreenAdminAppointmentsState extends State<ScreenAdminAppointments> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Lịch hẹn & Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointments
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lịch hẹn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                          DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                          DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                        ],
                        onChanged: (value) => setState(() => _filterStatus = value!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 10,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final statuses = ['Chờ', 'Đã xác nhận', 'Hoàn thành'];
                          final colors = [Colors.orange, Colors.blue, Colors.green];
                          final status = statuses[index % 3];
                          final color = colors[index % 3];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(Icons.calendar_today, color: color, size: 20),
                            ),
                            title: Text('Lịch hẹn #${1000 + index}'),
                            subtitle: Text('BN: User ${index + 1} • BS: Nguyễn Văn A\n${16 + index}/11/2025 - 10:00'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(status, style: TextStyle(color: color, fontSize: 12)),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Chat stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thống kê Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _StatCard(title: 'Tổng cuộc trò chuyện', value: '234', color: Colors.blue),
                  const SizedBox(height: 16),
                  _StatCard(title: 'Đang hoạt động', value: '45', color: Colors.green),
                  const SizedBox(height: 16),
                  _StatCard(title: 'Chờ phản hồi', value: '12', color: Colors.orange),
                  const SizedBox(height: 24),
                  const Text('Hoạt động gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 8,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(Icons.chat, color: Colors.blue, size: 20),
                            ),
                            title: Text('User ${index + 1} ↔ BS. Nguyễn Văn A'),
                            subtitle: Text('${index + 1} phút trước'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chat, color: color, size: 32),
          ),
        ],
      ),
    );
  }
}
