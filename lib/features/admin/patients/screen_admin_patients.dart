import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ScreenAdminPatients extends StatefulWidget {
  const ScreenAdminPatients({super.key});

  @override
  State<ScreenAdminPatients> createState() => _ScreenAdminPatientsState();
}

class _ScreenAdminPatientsState extends State<ScreenAdminPatients> {
  final _db = FirebaseDatabase.instance.ref();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Load all users with role 'user' (patients)
      final usersSnapshot = await _db.child('users').get();
      
      if (!usersSnapshot.exists || usersSnapshot.value == null) {
        setState(() {
          _allPatients = [];
          _filteredPatients = [];
          _isLoading = false;
        });
        return;
      }

      final usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
      final patients = <Map<String, dynamic>>[];

      for (var entry in usersData.entries) {
        final userData = Map<String, dynamic>.from(entry.value as Map);
        final role = userData['role'] as String? ?? 'user';
        
        // Only include users with role 'user' (not doctors or admins)
        if (role == 'user') {
          // Get latest prediction for this user
          String status = 'stable';
          try {
            final predSnapshot = await _db
                .child('predictions')
                .orderByChild('userId')
                .equalTo(entry.key)
                .limitToLast(1)
                .get();
            
            if (predSnapshot.exists && predSnapshot.value != null) {
              final predData = Map<String, dynamic>.from(predSnapshot.value as Map);
              final latestPred = predData.entries.first.value as Map;
              final riskLevel = latestPred['riskLevel'] as String? ?? 'low';
              if (riskLevel == 'high') {
                status = 'high_risk';
              } else if (riskLevel == 'medium') {
                status = 'warning';
              }
            }
          } catch (e) {
            // Ignore prediction fetch errors
          }

          patients.add({
            'id': entry.key,
            'name': userData['name'] ?? 'Không tên',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'age': userData['age'] ?? 0,
            'gender': userData['gender'] ?? '',
            'status': status,
            'createdAt': userData['createdAt'] ?? 0,
            'photoURL': userData['photoURL'] ?? '',
          });
        }
      }

      // Sort by createdAt descending
      patients.sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      setState(() {
        _allPatients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPatients = _allPatients);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        final name = (patient['name'] as String).toLowerCase();
        final email = (patient['email'] as String).toLowerCase();
        final phone = (patient['phone'] as String).toLowerCase();
        final id = (patient['id'] as String).toLowerCase();
        return name.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            phone.contains(lowerQuery) ||
            id.contains(lowerQuery);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'high_risk':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'high_risk':
        return 'Nguy cơ cao';
      case 'warning':
        return 'Cảnh báo';
      default:
        return 'Ổn định';
    }
  }

  void _showPatientDetail(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: (patient['photoURL'] as String).isNotEmpty
                      ? NetworkImage(patient['photoURL'])
                      : null,
                  child: (patient['photoURL'] as String).isEmpty
                      ? Text(
                          (patient['name'] as String).isNotEmpty
                              ? (patient['name'] as String)[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'] ?? 'Không tên',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(patient['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(patient['status']),
                          style: TextStyle(
                            color: _getStatusColor(patient['status']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'ID', value: patient['id'] ?? ''),
            _DetailRow(label: 'Email', value: patient['email'] ?? 'Chưa cập nhật'),
            _DetailRow(label: 'Điện thoại', value: patient['phone'] ?? 'Chưa cập nhật'),
            _DetailRow(label: 'Tuổi', value: '${patient['age'] ?? 'N/A'}'),
            _DetailRow(label: 'Giới tính', value: patient['gender'] ?? 'Chưa cập nhật'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đóng', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Quản lý Bệnh nhân'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPatients,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bệnh nhân...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                _StatCard(
                  title: 'Tổng bệnh nhân',
                  value: '${_allPatients.length}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Nguy cơ cao',
                  value: '${_allPatients.where((p) => p['status'] == 'high_risk').length}',
                  color: Colors.red,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Ổn định',
                  value: '${_allPatients.where((p) => p['status'] == 'stable').length}',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Patient list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(_error),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadPatients,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : _filteredPatients.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Không tìm thấy bệnh nhân nào'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredPatients.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final patient = _filteredPatients[index];
                                  final status = patient['status'] as String;
                                  final statusColor = _getStatusColor(status);

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: statusColor.withOpacity(0.1),
                                      backgroundImage: (patient['photoURL'] as String).isNotEmpty
                                          ? NetworkImage(patient['photoURL'])
                                          : null,
                                      child: (patient['photoURL'] as String).isEmpty
                                          ? Text(
                                              (patient['name'] as String).isNotEmpty
                                                  ? (patient['name'] as String)[0].toUpperCase()
                                                  : 'P',
                                              style: TextStyle(color: statusColor),
                                            )
                                          : null,
                                    ),
                                    title: Text(patient['name'] ?? 'Không tên'),
                                    subtitle: Text(
                                      'ID: ${(patient['id'] as String).substring(0, 8)}... • ${patient['email'] ?? ''}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusText(status),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                          onPressed: () => _showPatientDetail(patient),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showPatientDetail(patient),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
}
