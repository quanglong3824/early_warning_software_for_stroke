import 'package:flutter/material.dart';
import 'dart:math';

class ScreenPatientProfile extends StatelessWidget {
  const ScreenPatientProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] ?? 'unknown';
    final patientName = args?['patientName'] ?? 'Bệnh nhân';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Bệnh nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medication),
            tooltip: 'Kê đơn thuốc',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/doctor/create-prescription',
                arguments: {
                  'userId': userId,
                  'patientName': patientName,
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(patientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ID: ${(userId as String).substring(0, min(8, (userId as String).length))}...', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildInfoSection('Thông tin cơ bản'),
            _buildInfoSection('Lịch sử khám bệnh'),
            _buildInfoSection('Kết quả xét nghiệm'),
            _buildInfoSection('Đơn thuốc hiện tại'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/doctor/create-prescription',
            arguments: {
              'userId': userId,
              'patientName': patientName,
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Kê đơn thuốc'),
        backgroundColor: const Color(0xFF135BEC),
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(title),
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nội dung chi tiết...'),
          ),
        ],
      ),
    );
  }
}
