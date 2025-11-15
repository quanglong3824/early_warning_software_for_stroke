import 'package:flutter/material.dart';

class ScreenSOSQueue extends StatelessWidget {
  const ScreenSOSQueue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hàng đợi SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.emergency, color: Colors.white),
              ),
              title: Text('SOS #${index + 1} - Nguyễn Văn A'),
              subtitle: const Text('Đột quỵ nghi ngờ • 2 phút trước'),
              trailing: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/doctor/sos-case'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xử lý'),
              ),
            ),
          );
        },
      ),
    );
  }
}
