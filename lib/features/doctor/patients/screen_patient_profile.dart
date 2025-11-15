import 'package:flutter/material.dart';

class ScreenPatientProfile extends StatelessWidget {
  const ScreenPatientProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ Bệnh nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text('Nguyễn Văn A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('65 tuổi • Nam', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildInfoSection('Thông tin cơ bản'),
            _buildInfoSection('Lịch sử khám bệnh'),
            _buildInfoSection('Kết quả xét nghiệm'),
            _buildInfoSection('Đơn thuốc hiện tại'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
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
