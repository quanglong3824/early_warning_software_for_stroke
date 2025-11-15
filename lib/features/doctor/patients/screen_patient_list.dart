import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenPatientList extends StatelessWidget {
  const ScreenPatientList({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final patients = appData.patients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Bệnh nhân'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text(patient.name[0])),
              title: Text(patient.name),
              subtitle: Text('${patient.mainValue} ${patient.unit}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, '/doctor/patient-profile'),
            ),
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 1),
    );
  }
}
