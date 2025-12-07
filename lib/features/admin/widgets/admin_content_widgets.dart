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

// ========== USERS CONTENT WITH FULL CRUD ==========
class AdminUsersContent extends StatefulWidget {
  const AdminUsersContent({super.key});

  @override
  State<AdminUsersContent> createState() => _AdminUsersContentState();
}

class _AdminUsersContentState extends State<AdminUsersContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _users = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
        _applyFilters();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          (user['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (user['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesRole = _roleFilter == 'all' || user['role'] == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _addUser() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'user';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF6B46C1)),
              SizedBox(width: 8),
              Text('Thêm User mới'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'doctor', child: Text('Bác sĩ')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedRole = value!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B46C1)),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      final newRef = _database.child('users').push();
      await newRef.set({
        'uid': newRef.key,
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'role': selectedRole,
        'isBlocked': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm user mới'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final phoneController = TextEditingController(text: user['phone']);
    String selectedRole = user['role'] ?? 'user';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sửa thông tin User'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'doctor', child: Text('Bác sĩ')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedRole = value!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _database.child('users/${user['id']}').update({
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'role': selectedRole,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin user'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  Future<void> _toggleBlockUser(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyBlocked ? 'Đã mở khóa user' : 'Đã khóa user'),
          backgroundColor: currentlyBlocked ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: const Text('Bạn có chắc muốn xóa user này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('users/$id').remove();
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa user'), backgroundColor: Colors.red),
        );
      }
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
          // Header with actions
          Row(
            children: [
              Text('${_filteredUsers.length} users', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Search
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Role filter
              DropdownButton<String>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'doctor', child: Text('Bác sĩ')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    _roleFilter = value!;
                    _applyFilters();
                  });
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm User', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B46C1)),
              ),
              const SizedBox(width: 8),
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
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _filteredUsers.map((user) => DataRow(cells: [
                    DataCell(Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(user['email'] ?? 'N/A')),
                    DataCell(Text(user['phone'] ?? 'N/A')),
                    DataCell(_RoleBadge(role: user['role'] ?? 'user')),
                    DataCell(_StatusBadge(isBlocked: user['isBlocked'] == true)),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editUser(user),
                          tooltip: 'Sửa',
                        ),
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

// ========== DOCTORS CONTENT WITH FULL CRUD ==========
class AdminDoctorsContent extends StatefulWidget {
  const AdminDoctorsContent({super.key});

  @override
  State<AdminDoctorsContent> createState() => _AdminDoctorsContentState();
}

class _AdminDoctorsContentState extends State<AdminDoctorsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _specialtyFilter = 'all';
  final _searchController = TextEditingController();

  final List<String> _specialties = ['Tim mạch', 'Thần kinh', 'Huyết áp', 'Nội khoa', 'Ngoại khoa', 'Đột quỵ', 'Khác'];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').orderByChild('role').equalTo('doctor').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _doctors = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
        _applyFilters();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredDoctors = _doctors.where((doc) {
      final matchesSearch = _searchQuery.isEmpty ||
          (doc['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (doc['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesSpecialty = _specialtyFilter == 'all' || doc['specialty'] == _specialtyFilter;
      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  Future<void> _addDoctor() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final hospitalController = TextEditingController();
    final experienceController = TextEditingController();
    String selectedSpecialty = 'Tim mạch';
    bool isVerified = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green),
              SizedBox(width: 8),
              Text('Thêm Bác sĩ mới'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialty,
                    decoration: const InputDecoration(
                      labelText: 'Chuyên khoa *',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) => setDialogState(() => selectedSpecialty = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hospitalController,
                    decoration: const InputDecoration(
                      labelText: 'Bệnh viện',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Số năm kinh nghiệm',
                      prefixIcon: Icon(Icons.work_history),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Đã xác minh'),
                    value: isVerified,
                    onChanged: (value) => setDialogState(() => isVerified = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      final newRef = _database.child('users').push();
      await newRef.set({
        'uid': newRef.key,
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'role': 'doctor',
        'specialty': selectedSpecialty,
        'hospital': hospitalController.text,
        'experience': int.tryParse(experienceController.text) ?? 0,
        'isVerified': isVerified,
        'isBlocked': false,
        'isAvailable': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm bác sĩ mới'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _editDoctor(Map<String, dynamic> doc) async {
    final nameController = TextEditingController(text: doc['name']);
    final emailController = TextEditingController(text: doc['email']);
    final phoneController = TextEditingController(text: doc['phone']);
    final hospitalController = TextEditingController(text: doc['hospital']);
    final experienceController = TextEditingController(text: doc['experience']?.toString() ?? '');
    String selectedSpecialty = doc['specialty'] ?? 'Tim mạch';
    bool isVerified = doc['isVerified'] == true;
    bool isAvailable = doc['isAvailable'] != false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sửa thông tin Bác sĩ'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _specialties.contains(selectedSpecialty) ? selectedSpecialty : 'Khác',
                    decoration: const InputDecoration(
                      labelText: 'Chuyên khoa *',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) => setDialogState(() => selectedSpecialty = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hospitalController,
                    decoration: const InputDecoration(
                      labelText: 'Bệnh viện',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Số năm kinh nghiệm',
                      prefixIcon: Icon(Icons.work_history),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Đã xác minh'),
                    subtitle: Text(isVerified ? 'Bác sĩ đã được xác minh' : 'Chưa xác minh'),
                    value: isVerified,
                    onChanged: (value) => setDialogState(() => isVerified = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Đang hoạt động'),
                    subtitle: Text(isAvailable ? 'Có thể nhận bệnh nhân' : 'Tạm ngưng'),
                    value: isAvailable,
                    onChanged: (value) => setDialogState(() => isAvailable = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _database.child('users/${doc['id']}').update({
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'specialty': selectedSpecialty,
        'hospital': hospitalController.text,
        'experience': int.tryParse(experienceController.text) ?? 0,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin bác sĩ'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  Future<void> _toggleVerify(String id, bool currentlyVerified) async {
    await _database.child('users/$id').update({'isVerified': !currentlyVerified});
    _loadDoctors();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyVerified ? 'Đã hủy xác minh bác sĩ' : 'Đã xác minh bác sĩ'),
          backgroundColor: currentlyVerified ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleBlockDoctor(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadDoctors();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyBlocked ? 'Đã mở khóa bác sĩ' : 'Đã khóa bác sĩ'),
          backgroundColor: currentlyBlocked ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteDoctor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Xác nhận xóa')],
        ),
        content: const Text('Bạn có chắc muốn xóa bác sĩ này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('users/$id').remove();
      _loadDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bác sĩ'), backgroundColor: Colors.red),
        );
      }
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
              Text('${_filteredDoctors.length} bác sĩ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _specialtyFilter,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Tất cả chuyên khoa')),
                  ..._specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (value) {
                  setState(() {
                    _specialtyFilter = value!;
                    _applyFilters();
                  });
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addDoctor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm Bác sĩ', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(width: 8),
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
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Chuyên khoa', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Xác minh', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _filteredDoctors.map((doc) => DataRow(cells: [
                    DataCell(Text(doc['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(doc['email'] ?? 'N/A')),
                    DataCell(Text(doc['phone'] ?? 'N/A')),
                    DataCell(_SpecialtyBadge(specialty: doc['specialty'] ?? 'N/A')),
                    DataCell(_VerifiedBadge(isVerified: doc['isVerified'] == true)),
                    DataCell(_StatusBadge(isBlocked: doc['isBlocked'] == true)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _editDoctor(doc),
                          tooltip: 'Sửa',
                        ),
                        IconButton(
                          icon: Icon(doc['isVerified'] == true ? Icons.verified : Icons.verified_outlined,
                              color: doc['isVerified'] == true ? Colors.green : Colors.grey, size: 20),
                          onPressed: () => _toggleVerify(doc['id'], doc['isVerified'] == true),
                          tooltip: doc['isVerified'] == true ? 'Hủy xác minh' : 'Xác minh',
                        ),
                        IconButton(
                          icon: Icon(doc['isBlocked'] == true ? Icons.lock_open : Icons.lock, color: Colors.orange, size: 20),
                          onPressed: () => _toggleBlockDoctor(doc['id'], doc['isBlocked'] == true),
                          tooltip: doc['isBlocked'] == true ? 'Mở khóa' : 'Khóa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteDoctor(doc['id']),
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

class _SpecialtyBadge extends StatelessWidget {
  final String specialty;
  const _SpecialtyBadge({required this.specialty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (specialty) {
      case 'Tim mạch': color = Colors.red; break;
      case 'Thần kinh': color = Colors.purple; break;
      case 'Huyết áp': color = Colors.blue; break;
      case 'Đột quỵ': color = Colors.orange; break;
      default: color = Colors.teal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(specialty, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  const _VerifiedBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified : Icons.pending, size: 14, color: isVerified ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(isVerified ? 'Đã xác minh' : 'Chưa', style: TextStyle(color: isVerified ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ========== PATIENTS CONTENT WITH FULL CRUD ==========
class AdminPatientsContent extends StatefulWidget {
  const AdminPatientsContent({super.key});

  @override
  State<AdminPatientsContent> createState() => _AdminPatientsContentState();
}

class _AdminPatientsContentState extends State<AdminPatientsContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
    setState(() => _isLoading = true);
    try {
      final snapshot = await _database.child('users').orderByChild('role').equalTo('user').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _patients = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
        _applyFilters();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredPatients = _patients.where((p) {
      return _searchQuery.isEmpty ||
          (p['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p['phone']?.toString().contains(_searchQuery) ?? false);
    }).toList();
  }

  Future<void> _viewPatientDetail(Map<String, dynamic> patient) async {
    // Load health records and predictions for this patient
    List<Map<String, dynamic>> healthRecords = [];
    List<Map<String, dynamic>> predictions = [];
    
    try {
      final healthSnapshot = await _database.child('healthRecords').orderByChild('userId').equalTo(patient['id']).get();
      if (healthSnapshot.exists) {
        final data = Map<String, dynamic>.from(healthSnapshot.value as Map);
        healthRecords = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      
      final predSnapshot = await _database.child('predictions').orderByChild('userId').equalTo(patient['id']).get();
      if (predSnapshot.exists) {
        final data = Map<String, dynamic>.from(predSnapshot.value as Map);
        predictions = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    }

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('Chi tiết: ${patient['name']}')),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  tabs: [
                    Tab(text: 'Thông tin'),
                    Tab(text: 'Sức khỏe'),
                    Tab(text: 'Dự đoán'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Basic Info
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: 'Họ tên', value: patient['name'] ?? 'N/A'),
                            _InfoRow(label: 'Email', value: patient['email'] ?? 'N/A'),
                            _InfoRow(label: 'SĐT', value: patient['phone'] ?? 'N/A'),
                            _InfoRow(label: 'Địa chỉ', value: patient['address'] ?? 'N/A'),
                            _InfoRow(label: 'Giới tính', value: patient['gender'] ?? 'N/A'),
                            _InfoRow(label: 'Ngày sinh', value: patient['dateOfBirth'] != null 
                                ? DateTime.fromMillisecondsSinceEpoch(patient['dateOfBirth']).toString().substring(0, 10) 
                                : 'N/A'),
                            _InfoRow(label: 'Trạng thái', value: patient['isBlocked'] == true ? 'Bị khóa' : 'Hoạt động'),
                          ],
                        ),
                      ),
                      // Tab 2: Health Records
                      healthRecords.isEmpty
                          ? const Center(child: Text('Chưa có hồ sơ sức khỏe'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: healthRecords.length,
                              itemBuilder: (ctx, i) {
                                final record = healthRecords[i];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.favorite, color: Colors.red),
                                    title: Text('Huyết áp: ${record['systolic'] ?? 'N/A'}/${record['diastolic'] ?? 'N/A'}'),
                                    subtitle: Text('Nhịp tim: ${record['heartRate'] ?? 'N/A'} bpm'),
                                    trailing: Text(record['recordedAt'] != null 
                                        ? DateTime.fromMillisecondsSinceEpoch(record['recordedAt']).toString().substring(0, 10) 
                                        : ''),
                                  ),
                                );
                              },
                            ),
                      // Tab 3: Predictions
                      predictions.isEmpty
                          ? const Center(child: Text('Chưa có dự đoán'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: predictions.length,
                              itemBuilder: (ctx, i) {
                                final pred = predictions[i];
                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      pred['type'] == 'stroke' ? Icons.favorite : Icons.water_drop,
                                      color: pred['riskLevel'] == 'high' ? Colors.red : Colors.orange,
                                    ),
                                    title: Text(pred['type'] == 'stroke' ? 'Đột quỵ' : 'Tiểu đường'),
                                    subtitle: Text('Nguy cơ: ${pred['riskScore'] ?? 0}%'),
                                    trailing: _RiskBadge(level: pred['riskLevel'] ?? 'low'),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _editPatient(Map<String, dynamic> patient) async {
    final nameController = TextEditingController(text: patient['name']);
    final emailController = TextEditingController(text: patient['email']);
    final phoneController = TextEditingController(text: patient['phone']);
    final addressController = TextEditingController(text: patient['address']);
    String? selectedGender = patient['gender'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Sửa thông tin Bệnh nhân')],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'Giới tính', prefixIcon: Icon(Icons.wc), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                      DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedGender = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _database.child('users/${patient['id']}').update({
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'gender': selectedGender,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin bệnh nhân'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  Future<void> _toggleBlockPatient(String id, bool currentlyBlocked) async {
    await _database.child('users/$id').update({'isBlocked': !currentlyBlocked});
    _loadPatients();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyBlocked ? 'Đã mở khóa bệnh nhân' : 'Đã khóa bệnh nhân'),
          backgroundColor: currentlyBlocked ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _deletePatient(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Xác nhận xóa')]),
        content: const Text('Bạn có chắc muốn xóa bệnh nhân này? Tất cả dữ liệu liên quan sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('users/$id').remove();
      _loadPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bệnh nhân'), backgroundColor: Colors.red),
        );
      }
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
              Text('${_filteredPatients.length} bệnh nhân', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email, SĐT...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
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
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _filteredPatients.map((p) => DataRow(cells: [
                    DataCell(Text(p['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p['email'] ?? 'N/A')),
                    DataCell(Text(p['phone'] ?? 'N/A')),
                    DataCell(Text(p['gender'] ?? 'N/A')),
                    DataCell(_StatusBadge(isBlocked: p['isBlocked'] == true)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                          onPressed: () => _viewPatientDetail(p),
                          tooltip: 'Xem chi tiết',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                          onPressed: () => _editPatient(p),
                          tooltip: 'Sửa',
                        ),
                        IconButton(
                          icon: Icon(p['isBlocked'] == true ? Icons.lock_open : Icons.lock, color: Colors.orange, size: 20),
                          onPressed: () => _toggleBlockPatient(p['id'], p['isBlocked'] == true),
                          tooltip: p['isBlocked'] == true ? 'Mở khóa' : 'Khóa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deletePatient(p['id']),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ========== SOS CONTENT WITH FULL CRUD ==========
class AdminSOSContent extends StatefulWidget {
  const AdminSOSContent({super.key});

  @override
  State<AdminSOSContent> createState() => _AdminSOSContentState();
}

class _AdminSOSContentState extends State<AdminSOSContent> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _sosRequests = [];
  List<Map<String, dynamic>> _filteredSOS = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load SOS requests
      final sosSnapshot = await _database.child('sos_requests').get();
      if (sosSnapshot.exists) {
        final data = Map<String, dynamic>.from(sosSnapshot.value as Map);
        _sosRequests = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
        _sosRequests.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        _applyFilters();
      }
      
      // Load doctors for assignment
      final docSnapshot = await _database.child('users').orderByChild('role').equalTo('doctor').get();
      if (docSnapshot.exists) {
        final data = Map<String, dynamic>.from(docSnapshot.value as Map);
        _doctors = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)}).toList();
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredSOS = _sosRequests.where((sos) {
      return _statusFilter == 'all' || sos['status'] == _statusFilter;
    }).toList();
  }

  Future<void> _viewSOSDetail(Map<String, dynamic> sos) async {
    // Load user info
    Map<String, dynamic>? userInfo;
    try {
      final userSnapshot = await _database.child('users/${sos['userId']}').get();
      if (userSnapshot.exists) {
        userInfo = Map<String, dynamic>.from(userSnapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: sos['status'] == 'pending' ? Colors.red : Colors.orange),
            const SizedBox(width: 8),
            const Text('Chi tiết SOS'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'ID', value: sos['id'] ?? 'N/A'),
                _InfoRow(label: 'Trạng thái', value: sos['status'] ?? 'pending'),
                _InfoRow(label: 'Thời gian', value: _formatDate(sos['createdAt'])),
                const Divider(),
                const Text('Thông tin bệnh nhân:', style: TextStyle(fontWeight: FontWeight.bold)),
                _InfoRow(label: 'Tên', value: userInfo?['name'] ?? 'N/A'),
                _InfoRow(label: 'SĐT', value: userInfo?['phone'] ?? 'N/A'),
                _InfoRow(label: 'Email', value: userInfo?['email'] ?? 'N/A'),
                if (sos['location'] != null) ...[
                  const Divider(),
                  const Text('Vị trí:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _InfoRow(label: 'Lat', value: sos['location']?['latitude']?.toString() ?? 'N/A'),
                  _InfoRow(label: 'Lng', value: sos['location']?['longitude']?.toString() ?? 'N/A'),
                ],
                if (sos['assignedDoctorId'] != null) ...[
                  const Divider(),
                  _InfoRow(label: 'Bác sĩ phụ trách', value: sos['assignedDoctorName'] ?? sos['assignedDoctorId']),
                ],
                if (sos['notes'] != null) ...[
                  const Divider(),
                  _InfoRow(label: 'Ghi chú', value: sos['notes']),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _assignDoctor(Map<String, dynamic> sos) async {
    String? selectedDoctorId = sos['assignedDoctorId'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [Icon(Icons.assignment_ind, color: Colors.blue), SizedBox(width: 8), Text('Gán bác sĩ')],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDoctorId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn bác sĩ',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                  ),
                  items: _doctors.map((doc) => DropdownMenuItem(
                    value: doc['id'] as String,
                    child: Text('${doc['name']} - ${doc['specialty'] ?? 'N/A'}'),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedDoctorId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: selectedDoctorId == null ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Gán', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDoctorId != null) {
      final doctor = _doctors.firstWhere((d) => d['id'] == selectedDoctorId, orElse: () => {});
      await _database.child('sos_requests/${sos['id']}').update({
        'assignedDoctorId': selectedDoctorId,
        'assignedDoctorName': doctor['name'],
        'status': 'responding',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gán bác sĩ cho ca SOS'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await _database.child('sos_requests/$id').update({
      'status': newStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus'), backgroundColor: Colors.blue),
      );
    }
  }

  Future<void> _deleteSOS(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Xác nhận xóa')]),
        content: const Text('Bạn có chắc muốn xóa yêu cầu SOS này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _database.child('sos_requests/$id').remove();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa yêu cầu SOS'), backgroundColor: Colors.red),
        );
      }
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

    // Count by status
    final pendingCount = _sosRequests.where((s) => s['status'] == 'pending').length;
    final respondingCount = _sosRequests.where((s) => s['status'] == 'responding').length;
    final resolvedCount = _sosRequests.where((s) => s['status'] == 'resolved').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          Row(
            children: [
              _MiniStatCard(title: 'Đang chờ', value: '$pendingCount', color: Colors.red),
              const SizedBox(width: 12),
              _MiniStatCard(title: 'Đang xử lý', value: '$respondingCount', color: Colors.orange),
              const SizedBox(width: 12),
              _MiniStatCard(title: 'Đã xử lý', value: '$resolvedCount', color: Colors.green),
              const Spacer(),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'pending', child: Text('Đang chờ')),
                  DropdownMenuItem(value: 'responding', child: Text('Đang xử lý')),
                  DropdownMenuItem(value: 'resolved', child: Text('Đã xử lý')),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value!;
                    _applyFilters();
                  });
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredSOS.isEmpty
                ? const Center(child: Text('Không có yêu cầu SOS'))
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredSOS.map((sos) => DataRow(cells: [
                          DataCell(Text(sos['id']?.toString().substring(0, 8) ?? '', style: const TextStyle(fontSize: 12))),
                          DataCell(Text(sos['userName'] ?? sos['userId']?.toString().substring(0, 8) ?? 'N/A')),
                          DataCell(Text(sos['assignedDoctorName'] ?? 'Chưa gán')),
                          DataCell(_SOSStatusBadge(status: sos['status'] ?? 'pending')),
                          DataCell(Text(_formatDate(sos['createdAt']), style: const TextStyle(fontSize: 12))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                onPressed: () => _viewSOSDetail(sos),
                                tooltip: 'Xem chi tiết',
                              ),
                              IconButton(
                                icon: const Icon(Icons.assignment_ind, color: Colors.green, size: 20),
                                onPressed: () => _assignDoctor(sos),
                                tooltip: 'Gán bác sĩ',
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) => _updateStatus(sos['id'], value),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'pending', child: Text('Đang chờ')),
                                  const PopupMenuItem(value: 'responding', child: Text('Đang xử lý')),
                                  const PopupMenuItem(value: 'resolved', child: Text('Đã xử lý')),
                                ],
                                child: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                tooltip: 'Đổi trạng thái',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteSOS(sos['id']),
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

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _MiniStatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
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
