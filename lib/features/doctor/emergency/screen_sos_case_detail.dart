import 'package:flutter/material.dart';

class ScreenSOSCaseDetail extends StatelessWidget {
  const ScreenSOSCaseDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Ca SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CẢNH BÁO KHẨN CẤP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Bệnh nhân: Nguyễn Văn A'),
                  Text('Triệu chứng: Đau đầu dữ dội, méo miệng'),
                  Text('Vị trí: 123 Đường ABC, Quận 1'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Hướng dẫn xử lý:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStep('1. Gọi cấp cứu 115 ngay lập tức'),
            _buildStep('2. Giữ bệnh nhân nằm yên, đầu hơi cao'),
            _buildStep('3. Không cho ăn uống'),
            _buildStep('4. Theo dõi nhịp thở và mạch'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call),
                label: const Text('Gọi cho bệnh nhân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
