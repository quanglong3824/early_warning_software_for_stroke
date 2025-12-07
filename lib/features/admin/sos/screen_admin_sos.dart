import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ScreenAdminSOS extends StatefulWidget {
  const ScreenAdminSOS({super.key});

  @override
  State<ScreenAdminSOS> createState() => _ScreenAdminSOSState();
}

class _ScreenAdminSOSState extends State<ScreenAdminSOS> {
  final _db = FirebaseDatabase.instance.ref();
  String _selectedTab = 'list';
  bool _isLoading = true;
  List<Map<String, dynamic>> _sosRequests = [];
  Map<String, int> _stats = {'total': 0, 'pending': 0, 'acknowledged': 0, 'dispatched': 0, 'resolved': 0};

  @override
  void initState() {
    super.initState();
    _loadSOSData();
  }

  Future<void> _loadSOSData() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await _db.child('sos_requests').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _sosRequests = [];
          _isLoading = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final requests = <Map<String, dynamic>>[];
      final stats = {'total': 0, 'pending': 0, 'acknowledged': 0, 'dispatched': 0, 'resolved': 0};

      for (var entry in data.entries) {
        final sosData = Map<String, dynamic>.from(entry.value as Map);
        final status = sosData['status'] as String? ?? 'pending';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;

        // Parse createdAt
        DateTime? createdAt;
        final createdAtValue = sosData['createdAt'];
        if (createdAtValue is String) {
          createdAt = DateTime.tryParse(createdAtValue);
        } else if (createdAtValue is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
        }

        requests.add({
          'id': entry.key,
          'patientName': sosData['patientName'] ?? 'Bệnh nhân',
          'userId': sosData['userId'] ?? '',
          'status': status,
          'createdAt': createdAt ?? DateTime.now(),
          'address': (sosData['userLocation'] as Map?)?['address'] ?? 'Không có địa chỉ',
          'notes': sosData['notes'] ?? '',
        });
      }

      // Sort by createdAt descending (newest first)
      requests.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      setState(() {
        _sosRequests = requests;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'acknowledged':
        return Colors.blue;
      case 'dispatched':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'acknowledged':
        return 'Đã tiếp nhận';
      case 'dispatched':
        return 'Đang xử lý';
      case 'resolved':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp SOS'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSOSData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _TabButton(
                  label: 'Danh sách',
                  icon: Icons.list,
                  isSelected: _selectedTab == 'list',
                  onTap: () => setState(() => _selectedTab = 'list'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Thống kê',
                  icon: Icons.analytics,
                  isSelected: _selectedTab == 'stats',
                  onTap: () => setState(() => _selectedTab = 'stats'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'list'
                    ? _buildListView()
                    : _buildStatsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_sosRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có yêu cầu SOS nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sosRequests.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final sos = _sosRequests[index];
          final status = sos['status'] as String;
          final createdAt = sos['createdAt'] as DateTime;
          final color = _getStatusColor(status);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, color: Colors.red),
            ),
            title: Text('SOS #${(sos['id'] as String).substring(0, 8)}'),
            subtitle: Text(
              '${sos['patientName']} • ${_formatTimeAgo(createdAt)}\n${sos['address']}',
            ),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            onTap: () => _showSOSDetail(sos),
          );
        },
      ),
    );
  }

  Widget _buildStatsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _StatCard(
            title: 'Tổng SOS',
            value: '${_stats['total']}',
            color: Colors.red,
          ),
          _StatCard(
            title: 'Đang chờ',
            value: '${_stats['pending']}',
            color: Colors.orange,
          ),
          _StatCard(
            title: 'Đang xử lý',
            value: '${_stats['dispatched']}',
            color: Colors.purple,
          ),
          _StatCard(
            title: 'Hoàn thành',
            value: '${_stats['resolved']}',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  void _showSOSDetail(Map<String, dynamic> sos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency, color: Colors.red, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS #${(sos['id'] as String).substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(sos['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(sos['status']),
                          style: TextStyle(
                            color: _getStatusColor(sos['status']),
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
            _DetailRow(label: 'Bệnh nhân', value: sos['patientName'] ?? 'N/A'),
            _DetailRow(
              label: 'Thời gian',
              value: DateFormat('HH:mm - dd/MM/yyyy').format(sos['createdAt'] as DateTime),
            ),
            _DetailRow(label: 'Địa chỉ', value: sos['address'] ?? 'N/A'),
            if ((sos['notes'] as String).isNotEmpty)
              _DetailRow(label: 'Ghi chú', value: sos['notes']),
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
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? primary : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? primary : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
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
