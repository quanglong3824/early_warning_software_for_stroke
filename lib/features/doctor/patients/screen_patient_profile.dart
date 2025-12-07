import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/patient_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/models/appointment_model.dart';

class ScreenPatientProfile extends StatefulWidget {
  const ScreenPatientProfile({super.key});

  @override
  State<ScreenPatientProfile> createState() => _ScreenPatientProfileState();
}

class _ScreenPatientProfileState extends State<ScreenPatientProfile>
    with SingleTickerProviderStateMixin {
  final _patientService = PatientService();
  final _authService = AuthService();
  final _noteController = TextEditingController();
  
  late TabController _tabController;
  String? _doctorId;
  String? _doctorName;
  PatientProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDoctorInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final doctorId = await _authService.getUserId();
    final doctorName = await _authService.getUserName();
    if (mounted) {
      setState(() {
        _doctorId = doctorId;
        _doctorName = doctorName;
      });
    }
  }

  Future<void> _loadPatientProfile(String patientId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _patientService.getPatientProfile(patientId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;
    if (userId != null && _profile == null && !_isLoading) {
      _loadPatientProfile(userId);
    } else if (userId != null && _profile == null) {
      _loadPatientProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] ?? 'unknown';
    final patientName = args?['patientName'] ?? 'Bệnh nhân';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Bệnh nhân'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Sức khỏe'),
            Tab(text: 'Lịch hẹn'),
            Tab(text: 'Ghi chú'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(userId, patientName),
                    _buildHealthTab(),
                    _buildAppointmentsTab(),
                    _buildNotesTab(userId),
                  ],
                ),
    );
  }

  Widget _buildInfoTab(String userId, String patientName) {
    final user = _profile?.user;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar and name
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue[100],
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.blue)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? patientName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(_profile?.healthStatus),
          const SizedBox(height: 24),

          // Basic info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin cơ bản',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(Icons.badge, 'ID', userId.substring(0, userId.length > 8 ? 8 : userId.length) + '...'),
                  _buildInfoRow(Icons.phone, 'Điện thoại', user?.phone ?? 'Chưa cập nhật'),
                  _buildInfoRow(Icons.email, 'Email', user?.email ?? 'Chưa cập nhật'),
                  _buildInfoRow(Icons.person, 'Giới tính', user?.gender ?? 'Chưa cập nhật'),
                  _buildInfoRow(
                    Icons.cake,
                    'Ngày sinh',
                    user?.dateOfBirth != null
                        ? dateFormat.format(user!.dateOfBirth!)
                        : 'Chưa cập nhật',
                  ),
                  _buildInfoRow(Icons.location_on, 'Địa chỉ', user?.address ?? 'Chưa cập nhật'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHealthTab() {
    final records = _profile?.healthRecords ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blood Pressure Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Huyết áp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildBloodPressureChart(records),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Heart Rate Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhịp tim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildHeartRateChart(records),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Health Records
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch sử đo gần đây',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có dữ liệu sức khỏe'),
                    )
                  else
                    ...records.take(5).map((r) => _buildHealthRecordItem(r)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart(List<HealthRecordModel> records) {
    final validRecords = records
        .where((r) => r.systolicBP != null && r.diastolicBP != null)
        .take(10)
        .toList()
        .reversed
        .toList();

    if (validRecords.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu huyết áp'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Systolic
          LineChartBarData(
            spots: validRecords.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.systolicBP!.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(show: true),
          ),
          // Diastolic
          LineChartBarData(
            spots: validRecords.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.diastolicBP!.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: true),
          ),
        ],
        minY: 40,
        maxY: 200,
      ),
    );
  }

  Widget _buildHeartRateChart(List<HealthRecordModel> records) {
    final validRecords = records
        .where((r) => r.heartRate != null)
        .take(10)
        .toList()
        .reversed
        .toList();

    if (validRecords.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu nhịp tim'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: validRecords.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.heartRate!.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.pink,
            barWidth: 2,
            dotData: FlDotData(show: true),
          ),
        ],
        minY: 40,
        maxY: 150,
      ),
    );
  }


  Widget _buildAppointmentsTab() {
    final appointments = _profile?.appointments ?? [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.isEmpty ? 1 : appointments.length,
      itemBuilder: (context, index) {
        if (appointments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có lịch hẹn nào'),
            ),
          );
        }

        final apt = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAppointmentStatusColor(apt.status).withOpacity(0.2),
              child: Icon(
                Icons.calendar_today,
                color: _getAppointmentStatusColor(apt.status),
              ),
            ),
            title: Text(
              dateFormat.format(DateTime.fromMillisecondsSinceEpoch(apt.appointmentTime)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apt.reason ?? 'Khám bệnh'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getAppointmentStatusColor(apt.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAppointmentStatusText(apt.status),
                    style: TextStyle(
                      color: _getAppointmentStatusColor(apt.status),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(String patientId) {
    return Column(
      children: [
        // Add note form
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _addNote(patientId),
              ),
            ],
          ),
        ),
        
        // Notes list
        Expanded(
          child: StreamBuilder<List<PatientNote>>(
            stream: _patientService.getPatientNotes(patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notes = snapshot.data ?? [];

              if (notes.isEmpty) {
                return const Center(
                  child: Text('Chưa có ghi chú nào'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return _buildNoteItem(notes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addNote(String patientId) async {
    if (_noteController.text.trim().isEmpty) return;
    if (_doctorId == null) return;

    final success = await _patientService.addPatientNote(
      patientId: patientId,
      doctorId: _doctorId!,
      doctorName: _doctorName ?? 'Bác sĩ',
      content: _noteController.text.trim(),
    );

    if (success && mounted) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm ghi chú')),
      );
    }
  }

  Widget _buildNoteItem(PatientNote note) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  note.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dateFormat.format(DateTime.fromMillisecondsSinceEpoch(note.createdAt)),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.content),
          ],
        ),
      ),
    );
  }


  // Helper widgets
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHealthRecordItem(HealthRecordModel record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRecordStatusColor(record).withOpacity(0.2),
        child: Icon(Icons.favorite, color: _getRecordStatusColor(record)),
      ),
      title: Text(
        dateFormat.format(DateTime.fromMillisecondsSinceEpoch(record.recordedAt)),
      ),
      subtitle: Text(
        'HA: ${record.bloodPressure} • Nhịp tim: ${record.heartRate ?? "N/A"}',
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'high_risk':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'stable':
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'high_risk':
        return 'Nguy cơ cao';
      case 'warning':
        return 'Cảnh báo';
      case 'stable':
      default:
        return 'Ổn định';
    }
  }

  Color _getAppointmentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAppointmentStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chờ xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return status;
    }
  }

  Color _getRecordStatusColor(HealthRecordModel record) {
    final bpStatus = record.getBPStatus();
    final hrStatus = record.getHeartRateStatus();

    if (bpStatus == 'high' || hrStatus == 'high') {
      return Colors.red;
    }
    if (bpStatus == 'low' || hrStatus == 'low') {
      return Colors.orange;
    }
    return Colors.green;
  }
}
