#!/bin/bash

# Script tạo các màn hình bác sĩ còn lại

BASE_DIR="/Applications/XAMPP/xamppfiles/htdocs/GitHub/early_warning_software_for_stroke/lib/features/doctor"

# Patient List
cat > "$BASE_DIR/patients/screen_patient_list.dart" << 'EOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_data_provider.dart';

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
    );
  }
}
EOF

# Patient Profile
cat > "$BASE_DIR/patients/screen_patient_profile.dart" << 'EOF'
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
EOF

# Appointment Management
cat > "$BASE_DIR/appointments/screen_appointment_management.dart" << 'EOF'
import 'package:flutter/material.dart';

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
EOF

# Appointment Request Detail
cat > "$BASE_DIR/appointments/screen_appointment_request_detail.dart" << 'EOF'
import 'package:flutter/material.dart';

class ScreenAppointmentRequestDetail extends StatelessWidget {
  const ScreenAppointmentRequestDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Yêu cầu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin bệnh nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Họ tên:', 'Nguyễn Văn A'),
            _buildInfoRow('Ngày sinh:', '01/01/1960'),
            _buildInfoRow('Lý do khám:', 'Tái khám định kỳ'),
            _buildInfoRow('Thời gian mong muốn:', '09:00 - 15/11/2024'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Chấp nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
EOF

# SOS Queue
cat > "$BASE_DIR/emergency/screen_sos_queue.dart" << 'EOF'
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
EOF

# SOS Case Detail
cat > "$BASE_DIR/emergency/screen_sos_case_detail.dart" << 'EOF'
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
EOF

echo "✅ Đã tạo các màn hình bác sĩ!"
EOF

chmod +x /Applications/XAMPP/xamppfiles/htdocs/GitHub/early_warning_software_for_stroke/generate_doctor_screens.sh
