import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/appointment_model.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenPatientList extends StatefulWidget {
  const ScreenPatientList({super.key});

  @override
  State<ScreenPatientList> createState() => _ScreenPatientListState();
}

class _ScreenPatientListState extends State<ScreenPatientList> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final doctorId = await _authService.getUserId();
    if (mounted) {
      setState(() => _doctorId = doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Bệnh nhân'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: _doctorId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<AppointmentModel>>(
              stream: _appointmentService.getDoctorAppointments(_doctorId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final appointments = snapshot.data ?? [];
                
                // Extract unique patients
                final Map<String, Map<String, dynamic>> uniquePatients = {};
                for (var apt in appointments) {
                  if (!uniquePatients.containsKey(apt.userId)) {
                    uniquePatients[apt.userId] = {
                      'userId': apt.userId,
                      'name': 'Bệnh nhân', // Default, ideally fetch from User service
                      // We can try to guess name if we had it in AppointmentModel, but we don't.
                      // For now, we'll use a placeholder or fetch it if possible.
                      // Actually, AppointmentService.getDoctorAppointments logic I added earlier 
                      // tried to fetch user details but didn't store it in AppointmentModel 
                      // because AppointmentModel doesn't have patientName.
                      // Let's just use "Bệnh nhân" + ID for now or modify AppointmentModel.
                      // Wait, I can't modify AppointmentModel easily without breaking things.
                      // I'll just use "Bệnh nhân" for now, or maybe I can fetch user details here.
                    };
                  }
                }

                final patients = uniquePatients.values.toList();

                if (patients.isEmpty) {
                  return const Center(child: Text('Chưa có bệnh nhân nào'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _PatientCard(
                      userId: patient['userId'],
                      // We will fetch the name inside the card
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 1),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String userId;

  const _PatientCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();

    return FutureBuilder<DataSnapshot>(
      future: db.child('users').child(userId).get(),
      builder: (context, snapshot) {
        String patientName = 'Đang tải...';
        String subtitle = 'ID: ${userId.substring(0, min(8, userId.length))}...';

        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.value != null) {
          final dynamic value = snapshot.data!.value;
          if (value is Map) {
             final data = Map<String, dynamic>.from(value);
             patientName = data['name'] ?? 'Bệnh nhân';
          }
          // You can add more details here like phone, age, etc.
        } else if (snapshot.hasError) {
          patientName = 'Lỗi tải tên';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(patientName),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/doctor/patient-profile',
                arguments: {
                  'userId': userId,
                  'patientName': patientName,
                },
              );
            },
          ),
        );
      },
    );
  }
}
