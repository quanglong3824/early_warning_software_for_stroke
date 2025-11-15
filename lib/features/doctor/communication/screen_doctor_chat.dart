import 'package:flutter/material.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenDoctorChat extends StatelessWidget {
  const ScreenDoctorChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Bệnh nhân ${index + 1}'),
            subtitle: const Text('Tin nhắn mới nhất...'),
            trailing: const Text('10:30'),
            onTap: () {},
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }
}
