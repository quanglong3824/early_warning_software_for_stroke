import 'package:flutter/material.dart';
import '../../../services/admin_doctor_service.dart';

class ScreenAdminDoctors extends StatefulWidget {
  const ScreenAdminDoctors({super.key});

  @override
  State<ScreenAdminDoctors> createState() => _ScreenAdminDoctorsState();
}

class _ScreenAdminDoctorsState extends State<ScreenAdminDoctors> {
  final TextEditingController _searchController = TextEditingController();
  final AdminDoctorService _doctorService = AdminDoctorService();
  
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    print('🔄 Loading doctors...');
    setState(() => _isLoading = true);
    
    try {
      final doctors = await _doctorService.getDoctorsByRole('doctor');
      print('✅ Loaded ${doctors.length} doctors');
      
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _applyFilters();
          _isLoading = false;
        });
        print('✅ UI updated with ${_filteredDoctors.length} filtered doctors');
      }
    } catch (e) {
      print('❌ Error loading doctors: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_doctors);

    // Filter by status
    if (_filterStatus == 'active') {
      filtered = filtered.where((u) => 
        (u['isBlocked'] ?? false) == false &&
        (u['isDeleted'] ?? false) == false
      ).toList();
    } else if (_filterStatus == 'blocked') {
      filtered = filtered.where((u) => 
        (u['isBlocked'] ?? false) == true
      ).toList();
    }

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query) || phone.contains(query);
      }).toList();
    }

    setState(() => _filteredDoctors = filtered);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Quản lý Bác sĩ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.pushNamed(context, '/admin/test-firebase'),
            tooltip: 'Test Firebase',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctors,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm doctor...',
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
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'blocked', child: Text('Bị chặn')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterStatus = value!);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDoctors,
                  tooltip: 'Làm mới',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddDoctorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Doctors table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDoctors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Không có doctor nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Table header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(flex: 2, child: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Số ĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 100, child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                              // Table rows
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _filteredDoctors.length,
                                  itemBuilder: (context, index) {
                                    final doctor = _filteredDoctors[index];
                                    final isBlocked = doctor['isBlocked'] ?? false;
                                    final isDeleted = doctor['isDeleted'] ?? false;
                                    
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                        color: isDeleted ? Colors.grey[100] : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: primary.withOpacity(0.1),
                                                  child: Text(
                                                    (doctor['name'] ?? 'U')[0].toUpperCase(),
                                                    style: TextStyle(color: primary),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    doctor['name'] ?? 'N/A',
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              doctor['email'] ?? 'N/A',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              doctor['phone'] ?? 'N/A',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDeleted
                                                    ? Colors.grey.withOpacity(0.1)
                                                    : isBlocked
                                                        ? Colors.red.withOpacity(0.1)
                                                        : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isDeleted ? 'Đã xóa' : isBlocked ? 'Bị chặn' : 'Hoạt động',
                                                style: TextStyle(
                                                  color: isDeleted
                                                      ? Colors.grey
                                                      : isBlocked
                                                          ? Colors.red
                                                          : Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _doctorService.formatTimestamp(doctor['createdAt']),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.visibility, size: 20),
                                                  onPressed: () => _showDoctorDetail(doctor),
                                                  tooltip: 'Xem chi tiết',
                                                ),
                                                if (!isDeleted)
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, size: 20),
                                                    onSelected: (value) {
                                                      switch (value) {
                                                        case 'edit':
                                                          _showEditDoctorDialog(doctor);
                                                          break;
                                                        case 'block':
                                                          _toggleDoctorStatus(doctor);
                                                          break;
                                                        case 'delete':
                                                          _deleteDoctor(doctor);
                                                          break;
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Sửa'),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'block',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              isBlocked ? Icons.lock_open : Icons.block,
                                                              size: 18,
                                                              color: isBlocked ? Colors.green : Colors.red,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(isBlocked ? 'Mở chặn' : 'Chặn'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Xóa', style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDoctorStatus(Map<String, dynamic> doctor) async {
    final isBlocked = doctor['isBlocked'] ?? false;
    final doctorId = doctor['uid'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBlocked ? 'Mở chặn Doctor' : 'Chặn Doctor'),
        content: Text(
          isBlocked
              ? 'Bạn có chắc muốn mở chặn "${doctor['name']}"?'
              : 'Bạn có chắc muốn chặn "${doctor['name']}"? Doctor sẽ không thể đăng nhập.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(isBlocked ? 'Mở chặn' : 'Chặn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _doctorService.toggleDoctorStatus(doctorId, !isBlocked);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      _loadDoctors();
    }
  }

  void _showAddDoctorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final specialtyController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm Bác sĩ mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Chuyên khoa',
                    border: OutlineInputBorder(),
                    hintText: 'VD: Tim mạch, Nội khoa...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    border: OutlineInputBorder(),
                    helperText: 'Tối thiểu 6 ký tự',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);

                      final result = await _doctorService.createDoctor(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text.isEmpty ? null : phoneController.text,
                        password: passwordController.text,
                        specialty: specialtyController.text.isEmpty ? null : specialtyController.text,
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success'] ? Colors.green : Colors.red,
                        ),
                      );

                      if (result['success']) {
                        await _loadDoctors();
                        // Reload dashboard stats if on dashboard
                        if (mounted) {
                          // Trigger a rebuild of parent widgets
                          setState(() {});
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDoctorDialog(Map<String, dynamic> doctor) {
    final nameController = TextEditingController(text: doctor['name']);
    final emailController = TextEditingController(text: doctor['email']);
    final phoneController = TextEditingController(text: doctor['phone'] ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa thông tin Doctor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: false, // Email không thể sửa
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);

                      final result = await _doctorService.updateDoctor(
                        doctor['uid'],
                        {
                          'name': nameController.text,
                          'phone': phoneController.text.isEmpty ? null : phoneController.text,
                        },
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success'] ? Colors.green : Colors.red,
                        ),
                      );

                      if (result['success']) {
                        _loadDoctors();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDoctor(Map<String, dynamic> doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Doctor'),
        content: Text('Bạn có chắc muốn xóa "${doctor['name']}"?\nDoctor sẽ không thể đăng nhập nữa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _doctorService.deleteDoctor(doctor['uid']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      _loadDoctors();
    }
  }

  void _showDoctorDetail(Map<String, dynamic> doctor) {
    final isBlocked = doctor['isBlocked'] ?? false;
    final isDeleted = doctor['isDeleted'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết Doctor: ${doctor['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'UID', value: doctor['uid'] ?? 'N/A'),
              _DetailRow(label: 'Tên', value: doctor['name'] ?? 'N/A'),
              _DetailRow(label: 'Email', value: doctor['email'] ?? 'N/A'),
              _DetailRow(label: 'Số điện thoại', value: doctor['phone'] ?? 'N/A'),
              _DetailRow(label: 'Role', value: doctor['role'] ?? 'N/A'),
              _DetailRow(
                label: 'Trạng thái',
                value: isDeleted
                    ? 'Đã xóa'
                    : isBlocked
                        ? 'Bị chặn'
                        : 'Hoạt động',
              ),
              _DetailRow(
                label: 'Phương thức đăng nhập',
                value: doctor['loginMethod'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Ngày tạo',
                value: _doctorService.formatTimestamp(doctor['createdAt']),
              ),
              _DetailRow(
                label: 'Cập nhật lần cuối',
                value: _doctorService.formatTimestamp(doctor['updatedAt']),
              ),
              if (doctor['lastLogin'] != null)
                _DetailRow(
                  label: 'Đăng nhập lần cuối',
                  value: _doctorService.formatRelativeTime(doctor['lastLogin']),
                ),
            ],
          ),
        ),
        actions: [
          if (!isDeleted) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditDoctorDialog(doctor);
              },
              child: const Text('Sửa'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleDoctorStatus(doctor);
              },
              child: Text(
                isBlocked ? 'Mở chặn' : 'Chặn',
                style: TextStyle(color: isBlocked ? Colors.green : Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDoctor(doctor);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
