import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/health_record_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/health_record_model.dart';

class ScreenHealthHistory extends StatefulWidget {
  const ScreenHealthHistory({super.key});

  @override
  State<ScreenHealthHistory> createState() => _ScreenHealthHistoryState();
}

class _ScreenHealthHistoryState extends State<ScreenHealthHistory> {
  final _healthService = HealthRecordService();
  final _authService = AuthService();
  
  String? _userId;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndStats();
  }

  Future<void> _loadUserAndStats() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      final stats = await _healthService.getHealthStats(userId);
      setState(() {
        _userId = userId;
        _stats = stats;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        appBar: AppBar(title: const Text('Lịch sử Sức khỏe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Lịch sử Sức khỏe'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/add-health-record');
              _loadUserAndStats();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserAndStats,
        child: StreamBuilder<List<HealthRecordModel>>(
          stream: _healthService.getHealthRecords(_userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            final records = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        'Huyết áp TB',
                        _stats['avgSystolic'] != null && _stats['avgDiastolic'] != null
                            ? '${_stats['avgSystolic']}/${_stats['avgDiastolic']}'
                            : 'N/A',
                        'mmHg',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        'Nhịp tim TB',
                        _stats['avgHeartRate']?.toString() ?? 'N/A',
                        'bpm',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử đo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${records.length} bản ghi',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bản ghi sức khỏe',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút + để thêm bản ghi mới',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...records.map((record) {
                    final bpStatus = record.getBPStatus();
                    final hrStatus = record.getHeartRateStatus();
                    final statusColor = _getStatusColor(bpStatus);

                    String dataText = '';
                    if (record.systolicBP != null && record.diastolicBP != null) {
                      dataText += 'HA: ${record.bloodPressure}';
                    }
                    if (record.heartRate != null) {
                      if (dataText.isNotEmpty) dataText += ', ';
                      dataText += 'Nhịp tim: ${record.heartRate}';
                    }
                    if (record.bloodSugar != null) {
                      if (dataText.isNotEmpty) dataText += ', ';
                      dataText += 'Đường huyết: ${record.bloodSugar}';
                    }
                    if (dataText.isEmpty) {
                      dataText = 'Không có dữ liệu';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryItem(
                        _formatDateTime(record.recordedAt),
                        dataText,
                        statusColor,
                        onTap: () {
                          // TODO: Navigate to detail screen
                        },
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;
  const _StatCard(this.title, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '$value $unit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date, data;
  final Color color;
  final VoidCallback? onTap;
  
  const _HistoryItem(this.date, this.data, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(data, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}