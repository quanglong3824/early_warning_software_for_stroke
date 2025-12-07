import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/admin_user_service.dart';
import '../../../services/admin_prediction_service.dart';

// ========== DASHBOARD CONTENT ==========
class AdminDashboardContent extends StatefulWidget {
  const AdminDashboardContent({super.key});

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  final AdminUserService _userService = AdminUserService();
  final AdminPredictionService _predictionService = AdminPredictionService();
  
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _predictionStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _userService.getUserStats();
      final predStats = await _predictionService.getPredictionStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _predictionStats = predStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thống kê người dùng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Tổng Users', value: '${_stats['users'] ?? 0}', icon: Icons.people, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Bác sĩ', value: '${_stats['doctors'] ?? 0}', icon: Icons.medical_services, color: Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Admins', value: '${_stats['admins'] ?? 0}', icon: Icons.admin_panel_settings, color: Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Bị chặn', value: '${_stats['blocked'] ?? 0}', icon: Icons.block, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Thống kê Dự đoán', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Tổng Dự đoán', value: '${_predictionStats['total'] ?? 0}', icon: Icons.analytics, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Đột quỵ', value: '${_predictionStats['stroke'] ?? 0}', icon: Icons.favorite, color: Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Tiểu đường', value: '${_predictionStats['diabetes'] ?? 0}', icon: Icons.water_drop, color: Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Nguy cơ cao', value: '${_predictionStats['highRisk'] ?? 0}', icon: Icons.warning, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}

// ========== USERS CONTENT WITH CRUD ==========
class AdminUsersContent extends StatefulWidget {
  const AdminUsersContent({super.key});

  @override
  State<AdminUsersContent> createState() => _AdminUsersContentState();
}

class _AdminUsersContentState extends State<AdminUsersContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _users = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlockUser(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadUsers();
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa user này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('users/$id').remove();
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_users.length} users', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadUsers, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _users.map((user) => DataRow(cells: [
                    DataCell(Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(user['email'] ?? 'N/A')),
                    DataCell(_RoleBadge(role: user['role'] ?? 'user')),
                    DataCell(_StatusBadge(isBlocked: user['isBlocked'] == true)),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(user['isBlocked'] == true ? Icons.lock_open : Icons.lock, color: Colors.orange),
                          onPressed: () => _toggleBlockUser(user['id'], user['isBlocked'] == true),
                          tooltip: user['isBlocked'] == true ? 'Mở khóa' : 'Khóa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['id']),
                          tooltip: 'Xóa',
                        ),
                      ],
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin': color = Colors.purple; break;
      case 'doctor': color = Colors.green; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(role, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBlocked;
  const _StatusBadge({required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBlocked ? 'Blocked' : 'Active',
        style: TextStyle(color: isBlocked ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ========== DOCTORS CONTENT WITH CRUD ==========
class AdminDoctorsContent extends StatefulWidget {
  const AdminDoctorsContent({super.key});

  @override
  State<AdminDoctorsContent> createState() => _AdminDoctorsContentState();
}

class _AdminDoctorsContentState extends State<AdminDoctorsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').orderByChild('role').equalTo('doctor').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _doctors = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlockDoctor(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadDoctors();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_doctors.length} bác sĩ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadDoctors, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Chuyên khoa', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _doctors.map((doc) => DataRow(cells: [
                    DataCell(Text(doc['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(doc['email'] ?? 'N/A')),
                    DataCell(Text(doc['phone'] ?? 'N/A')),
                    DataCell(Text(doc['specialty'] ?? 'N/A')),
                    DataCell(_StatusBadge(isBlocked: doc['isBlocked'] == true)),
                    DataCell(IconButton(
                      icon: Icon(doc['isBlocked'] == true ? Icons.lock_open : Icons.lock, color: Colors.orange),
                      onPressed: () => _toggleBlockDoctor(doc['id'], doc['isBlocked'] == true),
                      tooltip: doc['isBlocked'] == true ? 'Mở khóa' : 'Khóa',
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PATIENTS CONTENT WITH CRUD ==========
class AdminPatientsContent extends StatefulWidget {
  const AdminPatientsContent({super.key});

  @override
  State<AdminPatientsContent> createState() => _AdminPatientsContentState();
}

class _AdminPatientsContentState extends State<AdminPatientsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').orderByChild('role').equalTo('user').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _patients = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlockPatient(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_patients.length} bệnh nhân', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadPatients, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _patients.map((p) => DataRow(cells: [
                    DataCell(Text(p['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p['email'] ?? 'N/A')),
                    DataCell(Text(p['phone'] ?? 'N/A')),
                    DataCell(_StatusBadge(isBlocked: p['isBlocked'] == true)),
                    DataCell(IconButton(
                      icon: Icon(p['isBlocked'] == true ? Icons.lock_open : Icons.lock, color: Colors.orange),
                      onPressed: () => _toggleBlockPatient(p['id'], p['isBlocked'] == true),
                      tooltip: p['isBlocked'] == true ? 'Mở khóa' : 'Khóa',
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== SOS CONTENT WITH CRUD ==========
class AdminSOSContent extends StatefulWidget {
  const AdminSOSContent({super.key});

  @override
  State<AdminSOSContent> createState() => _AdminSOSContentState();
}

class _AdminSOSContentState extends State<AdminSOSContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _sosRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSOS();
  }

  Future<void> _loadSOS() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('sos_requests').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _sosRequests = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await _database.child('sos_requests/$id').update({
      'status': newStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _loadSOS();
  }

  Future<void> _deleteSOS(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa yêu cầu SOS này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('sos_requests/$id').remove();
      _loadSOS();
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int).toString().substring(0, 16);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_sosRequests.length} yêu cầu SOS', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadSOS, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _sosRequests.isEmpty
              ? const Center(child: Text('Không có yêu cầu SOS'))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _sosRequests.map((sos) => DataRow(cells: [
                        DataCell(Text(sos['id']?.toString().substring(0, 10) ?? '')),
                        DataCell(Text(sos['userId']?.toString().substring(0, 10) ?? 'N/A')),
                        DataCell(_SOSStatusBadge(status: sos['status'] ?? 'pending')),
                        DataCell(Text(_formatDate(sos['createdAt']))),
                        DataCell(Row(
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) => _updateStatus(sos['id'], value),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'pending', child: Text('Pending')),
                                const PopupMenuItem(value: 'responding', child: Text('Responding')),
                                const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                              ],
                              child: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSOS(sos['id'])),
                          ],
                        )),
                      ])).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _SOSStatusBadge extends StatelessWidget {
  final String status;
  const _SOSStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'resolved': color = Colors.green; break;
      case 'responding': color = Colors.orange; break;
      default: color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ========== PREDICTIONS CONTENT ==========
class AdminPredictionsContent extends StatefulWidget {
  const AdminPredictionsContent({super.key});

  @override
  State<AdminPredictionsContent> createState() => _AdminPredictionsContentState();
}

class _AdminPredictionsContentState extends State<AdminPredictionsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('predictions').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _predictions = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePrediction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa dự đoán này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('predictions/$id').remove();
      _loadPredictions();
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int).toString().substring(0, 10);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_predictions.length} dự đoán', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadPredictions, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Loại', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Nguy cơ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _predictions.map((p) => DataRow(cells: [
                    DataCell(_TypeBadge(type: p['type'] ?? 'N/A')),
                    DataCell(_RiskBadge(level: p['riskLevel'] ?? 'low')),
                    DataCell(Text('${p['riskScore'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p['userId']?.toString().substring(0, 10) ?? 'N/A')),
                    DataCell(Text(_formatDate(p['createdAt']))),
                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePrediction(p['id']))),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color = type == 'stroke' ? Colors.red : Colors.orange;
    String label = type == 'stroke' ? 'Đột quỵ' : 'Tiểu đường';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;
  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (level) {
      case 'high': color = Colors.red; label = 'Cao'; break;
      case 'medium': color = Colors.orange; label = 'Trung bình'; break;
      default: color = Colors.green; label = 'Thấp';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ========== APPOINTMENTS CONTENT WITH CRUD ==========
class AdminAppointmentsContent extends StatefulWidget {
  const AdminAppointmentsContent({super.key});

  @override
  State<AdminAppointmentsContent> createState() => _AdminAppointmentsContentState();
}

class _AdminAppointmentsContentState extends State<AdminAppointmentsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('appointments').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _appointments = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await _database.child('appointments/$id').update({
      'status': newStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _loadAppointments();
  }

  Future<void> _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa lịch hẹn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('appointments/$id').remove();
      _loadAppointments();
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int).toString().substring(0, 16);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_appointments.length} lịch hẹn', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadAppointments, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Địa điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Lý do', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _appointments.map((a) => DataRow(cells: [
                    DataCell(Text(a['doctorName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(a['location'] ?? 'N/A')),
                    DataCell(Text(a['reason'] ?? 'N/A')),
                    DataCell(_AppointmentStatusBadge(status: a['status'] ?? 'pending')),
                    DataCell(Text(_formatDate(a['appointmentTime']))),
                    DataCell(Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (value) => _updateStatus(a['id'], value),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'pending', child: Text('Pending')),
                            const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
                            const PopupMenuItem(value: 'completed', child: Text('Completed')),
                            const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          ],
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAppointment(a['id'])),
                      ],
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentStatusBadge extends StatelessWidget {
  final String status;
  const _AppointmentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'completed': color = Colors.blue; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ========== KNOWLEDGE CONTENT WITH CRUD ==========
class AdminKnowledgeContent extends StatefulWidget {
  const AdminKnowledgeContent({super.key});

  @override
  State<AdminKnowledgeContent> createState() => _AdminKnowledgeContentState();
}

class _AdminKnowledgeContentState extends State<AdminKnowledgeContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('knowledge_articles').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _articles = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addArticle() async {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm bài viết'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Danh mục')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Nội dung'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final newRef = _database.child('knowledge_articles').push();
      await newRef.set({
        'id': newRef.key,
        'title': titleController.text,
        'category': categoryController.text,
        'content': contentController.text,
        'author': 'Admin',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadArticles();
    }
  }

  Future<void> _deleteArticle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bài viết này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('knowledge_articles/$id').remove();
      _loadArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_articles.length} bài viết', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addArticle,
                icon: const Icon(Icons.add),
                label: const Text('Thêm bài viết'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _loadArticles, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _articles.isEmpty
              ? const Center(child: Text('Không có bài viết'))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                      columns: const [
                        DataColumn(label: Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Tác giả', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _articles.map((a) => DataRow(cells: [
                        DataCell(Text(a['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(a['category'] ?? 'N/A')),
                        DataCell(Text(a['author'] ?? 'N/A')),
                        DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteArticle(a['id']))),
                      ])).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// ========== COMMUNITY CONTENT WITH CRUD ==========
class AdminCommunityContent extends StatefulWidget {
  const AdminCommunityContent({super.key});

  @override
  State<AdminCommunityContent> createState() => _AdminCommunityContentState();
}

class _AdminCommunityContentState extends State<AdminCommunityContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _threads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('forum_threads').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _threads = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteThread(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa chủ đề này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('forum_threads/$id').remove();
      _loadThreads();
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int).toString().substring(0, 10);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_threads.length} chủ đề', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _loadThreads, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _threads.isEmpty
              ? const Center(child: Text('Không có chủ đề'))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                      columns: const [
                        DataColumn(label: Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Tác giả', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Lượt xem', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _threads.map((t) => DataRow(cells: [
                        DataCell(Text(t['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(t['authorName'] ?? 'N/A')),
                        DataCell(Text('${t['viewCount'] ?? 0}')),
                        DataCell(Text(_formatDate(t['createdAt']))),
                        DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteThread(t['id']))),
                      ])).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
