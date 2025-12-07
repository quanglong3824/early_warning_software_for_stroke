import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ScreenAdminAppointments extends StatefulWidget {
  const ScreenAdminAppointments({super.key});

  @override
  State<ScreenAdminAppointments> createState() => _ScreenAdminAppointmentsState();
}

class _ScreenAdminAppointmentsState extends State<ScreenAdminAppointments> {
  final _db = FirebaseDatabase.instance.ref();
  String _filterStatus = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _conversations = [];
  Map<String, int> _appointmentStats = {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0};
  Map<String, int> _chatStats = {'total': 0, 'active': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAppointments(),
      _loadConversations(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAppointments() async {
    try {
      final snapshot = await _db.child('appointments').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        setState(() => _appointments = []);
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final appointments = <Map<String, dynamic>>[];
      final stats = {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};

      for (var entry in data.entries) {
        final appointmentData = Map<String, dynamic>.from(entry.value as Map);
        final status = appointmentData['status'] as String? ?? 'pending';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;

        // Get doctor name
        String doctorName = 'Bác sĩ';
        final doctorId = appointmentData['doctorId'] as String?;
        if (doctorId != null) {
          try {
            final doctorSnapshot = await _db.child('users/$doctorId/name').get();
            if (doctorSnapshot.exists) {
              doctorName = doctorSnapshot.value as String? ?? 'Bác sĩ';
            }
          } catch (e) {
            // Use default
          }
        }

        // Get patient name
        String patientName = 'Bệnh nhân';
        final userId = appointmentData['userId'] as String?;
        if (userId != null) {
          try {
            final userSnapshot = await _db.child('users/$userId/name').get();
            if (userSnapshot.exists) {
              patientName = userSnapshot.value as String? ?? 'Bệnh nhân';
            }
          } catch (e) {
            // Use default
          }
        }

        appointments.add({
          'id': entry.key,
          'doctorName': doctorName,
          'patientName': patientName,
          'status': status,
          'appointmentTime': appointmentData['appointmentTime'] ?? 0,
          'type': appointmentData['type'] ?? 'Khám bệnh',
          'notes': appointmentData['notes'] ?? '',
        });
      }

      // Sort by appointmentTime descending
      appointments.sort((a, b) => (b['appointmentTime'] as int).compareTo(a['appointmentTime'] as int));

      setState(() {
        _appointments = appointments;
        _appointmentStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    }
  }

  Future<void> _loadConversations() async {
    try {
      final snapshot = await _db.child('conversations').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        setState(() => _conversations = []);
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final conversations = <Map<String, dynamic>>[];
      int totalCount = 0;
      int activeCount = 0;

      for (var entry in data.entries) {
        final convData = Map<String, dynamic>.from(entry.value as Map);
        totalCount++;
        
        final lastMessageTime = convData['lastMessageTime'] as int? ?? 0;
        final isActive = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMessageTime)
        ).inHours < 24;
        
        if (isActive) activeCount++;

        conversations.add({
          'id': entry.key,
          'lastMessageTime': lastMessageTime,
          'participants': convData['participants'] ?? {},
        });
      }

      // Sort by lastMessageTime descending
      conversations.sort((a, b) => (b['lastMessageTime'] as int).compareTo(a['lastMessageTime'] as int));

      setState(() {
        _conversations = conversations.take(10).toList();
        _chatStats = {'total': totalCount, 'active': activeCount};
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_filterStatus == 'all') return _appointments;
    return _appointments.where((a) => a['status'] == _filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDateTime(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  String _formatTimeAgo(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(dt);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Lịch hẹn & Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointments
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lịch hẹn (${_appointmentStats['total']})',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: _filterStatus,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                                DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                                DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                                DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                              ],
                              onChanged: (value) => setState(() => _filterStatus = value!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _filteredAppointments.isEmpty
                                ? const Center(child: Text('Không có lịch hẹn'))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredAppointments.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final appointment = _filteredAppointments[index];
                                      final status = appointment['status'] as String;
                                      final color = _getStatusColor(status);

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: color.withOpacity(0.1),
                                          child: Icon(Icons.calendar_today, color: color, size: 20),
                                        ),
                                        title: Text('${appointment['patientName']}'),
                                        subtitle: Text(
                                          'BS: ${appointment['doctorName']}\n${_formatDateTime(appointment['appointmentTime'])}',
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusText(status),
                                            style: TextStyle(color: color, fontSize: 12),
                                          ),
                                        ),
                                        isThreeLine: true,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Chat stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thống kê Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _StatCard(title: 'Tổng cuộc trò chuyện', value: '${_chatStats['total']}', color: Colors.blue),
                        const SizedBox(height: 16),
                        _StatCard(title: 'Đang hoạt động (24h)', value: '${_chatStats['active']}', color: Colors.green),
                        const SizedBox(height: 24),
                        const Text('Hoạt động gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _conversations.isEmpty
                                ? const Center(child: Text('Không có hội thoại'))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _conversations.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final conv = _conversations[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue.withOpacity(0.1),
                                          child: const Icon(Icons.chat, color: Colors.blue, size: 20),
                                        ),
                                        title: Text('Cuộc trò chuyện #${index + 1}'),
                                        subtitle: Text(_formatTimeAgo(conv['lastMessageTime'] as int)),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
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

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chat, color: color, size: 32),
          ),
        ],
      ),
    );
  }
}
