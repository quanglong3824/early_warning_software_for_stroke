import 'package:flutter/material.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenAppointmentManagement extends StatelessWidget {
  const ScreenAppointmentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Lịch hẹn')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Hôm nay'),
                Tab(text: 'Sắp tới'),
                Tab(text: 'Yêu cầu'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAppointmentList(),
                  _buildAppointmentList(),
                  _buildAppointmentList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 2),
    );
  }

  Widget _buildAppointmentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.calendar_today)),
            title: Text('Bệnh nhân ${index + 1}'),
            subtitle: const Text('09:00 - Khám tổng quát'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
