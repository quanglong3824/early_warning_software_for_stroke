import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/patient_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenPatientList extends StatefulWidget {
  const ScreenPatientList({super.key});

  @override
  State<ScreenPatientList> createState() => _ScreenPatientListState();
}

class _ScreenPatientListState extends State<ScreenPatientList> {
  final _patientService = PatientService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  String? _doctorId;
  bool _isSearching = false;
  List<PatientSummary> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDoctorId() async {
    final doctorId = await _authService.getUserId();
    if (mounted) {
      setState(() => _doctorId = doctorId);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_doctorId == null) return;
      
      final results = await _patientService.searchPatients(_doctorId!, query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Bệnh nhân'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, SĐT, ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Patient list
          Expanded(
            child: _doctorId == null
                ? const Center(child: CircularProgressIndicator())
                : _buildPatientList(),
          ),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 1),
    );
  }

  Widget _buildPatientList() {
    // If searching, show search results
    if (_searchController.text.isNotEmpty) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (_searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy bệnh nhân',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _PatientCard(patient: _searchResults[index]);
        },
      );
    }

    // Show all patients from stream
    return StreamBuilder<List<PatientSummary>>(
      stream: _patientService.getDoctorPatients(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}'),
              ],
            ),
          );
        }

        final patients = snapshot.data ?? [];

        if (patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bệnh nhân nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            return _PatientCard(patient: patients[index]);
          },
        );
      },
    );
  }
}


class _PatientCard extends StatelessWidget {
  final PatientSummary patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/doctor/patient-profile',
            arguments: {
              'userId': patient.id,
              'patientName': patient.name,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getStatusColor(patient.healthStatus).withOpacity(0.2),
                backgroundImage: patient.avatarUrl != null
                    ? NetworkImage(patient.avatarUrl!)
                    : null,
                child: patient.avatarUrl == null
                    ? Icon(Icons.person, color: _getStatusColor(patient.healthStatus))
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(patient.healthStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (patient.phone != null)
                      Text(
                        patient.phone!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    const SizedBox(height: 4),
                    _buildHealthInfo(patient),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHealthInfo(PatientSummary patient) {
    final record = patient.latestHealthRecord;
    if (record == null) {
      return Text(
        'Chưa có dữ liệu sức khỏe',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      );
    }

    final List<String> info = [];
    if (record.systolicBP != null && record.diastolicBP != null) {
      info.add('HA: ${record.systolicBP}/${record.diastolicBP}');
    }
    if (record.heartRate != null) {
      info.add('Nhịp tim: ${record.heartRate}');
    }

    if (info.isEmpty) {
      return Text(
        'Chưa có dữ liệu sức khỏe',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      );
    }

    return Text(
      info.join(' • '),
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
    );
  }

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
}
