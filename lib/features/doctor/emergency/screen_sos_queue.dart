import 'package:flutter/material.dart';
import '../../../services/sos_service.dart';
import '../../../services/auth_service.dart';

class ScreenSOSQueue extends StatefulWidget {
  const ScreenSOSQueue({super.key});

  @override
  State<ScreenSOSQueue> createState() => _ScreenSOSQueueState();
}

class _ScreenSOSQueueState extends State<ScreenSOSQueue> {
  final SOSService _sosService = SOSService();
  final AuthService _authService = AuthService();
  String? _doctorId;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    final session = await _authService.getUserSession();
    setState(() {
      _doctorId = session['userId'];
      _doctorName = session['userName'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hàng đợi SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<int>(
            stream: _sosService.getActiveSOSCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count ca đang chờ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SOSCaseModel>>(
        stream: _sosService.getSOSCasesByPriority(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final sosCases = snapshot.data ?? [];

          if (sosCases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có ca SOS nào đang chờ',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tất cả các ca đã được xử lý',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sosCases.length,
              itemBuilder: (context, index) {
                final sosCase = sosCases[index];
                return _buildSOSCard(sosCase);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSOSCard(SOSCaseModel sosCase) {
    final statusColor = _getStatusColor(sosCase.status);
    final statusText = _getStatusText(sosCase.status);
    final priorityLevel = _getPriorityLevel(sosCase.waitTimeMinutes);

    return Card(
      color: statusColor.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(sosCase.sosId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emergency, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sosCase.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${sosCase.sosId.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(priorityLevel),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Info rows
              _buildInfoRow(Icons.access_time, 'Thời gian chờ', '${sosCase.waitTimeMinutes} phút'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Vị trí', sosCase.address, maxLines: 2),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.info_outline, 'Trạng thái', statusText),
              if (sosCase.acknowledgedByName != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Tiếp nhận bởi', sosCase.acknowledgedByName!),
              ],
              const SizedBox(height: 16),
              // Action button
              _buildActionButton(sosCase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String level) {
    Color color;
    switch (level) {
      case 'Khẩn cấp':
        color = Colors.red;
        break;
      case 'Cao':
        color = Colors.orange;
        break;
      default:
        color = Colors.yellow.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(SOSCaseModel sosCase) {
    if (sosCase.status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _acknowledgeCase(sosCase),
          icon: const Icon(Icons.check_circle),
          label: const Text('Tiếp nhận'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (sosCase.status == 'acknowledged') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _navigateToDetail(sosCase.sosId),
              icon: const Icon(Icons.visibility),
              label: const Text('Chi tiết'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _dispatchCase(sosCase),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Điều phối'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToDetail(sosCase.sosId),
          icon: const Icon(Icons.visibility),
          label: const Text('Xem chi tiết'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'dispatched':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ xử lý';
      case 'acknowledged':
        return 'Đã tiếp nhận';
      case 'dispatched':
        return 'Đang điều phối';
      default:
        return status;
    }
  }

  String _getPriorityLevel(int waitTimeMinutes) {
    if (waitTimeMinutes >= 10) {
      return 'Khẩn cấp';
    } else if (waitTimeMinutes >= 5) {
      return 'Cao';
    } else {
      return 'Trung bình';
    }
  }

  void _navigateToDetail(String sosId) {
    Navigator.pushNamed(context, '/doctor/sos-case', arguments: sosId);
  }

  Future<void> _acknowledgeCase(SOSCaseModel sosCase) async {
    if (_doctorId == null || _doctorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác định thông tin bác sĩ')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tiếp nhận'),
        content: Text('Bạn có chắc muốn tiếp nhận ca SOS của ${sosCase.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tiếp nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _sosService.acknowledgeSOSCase(
        sosCase.sosId,
        _doctorId!,
        _doctorName!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Đã tiếp nhận ca SOS thành công' 
                : 'Không thể tiếp nhận ca SOS'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _dispatchCase(SOSCaseModel sosCase) async {
    if (_doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác định thông tin bác sĩ')),
      );
      return;
    }

    final notesController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều phối cấp cứu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điều phối đội cấp cứu đến hỗ trợ ${sosCase.patientName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Điều phối'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _sosService.dispatchSOSCase(
        sosCase.sosId,
        _doctorId!,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Đã điều phối cấp cứu thành công' 
                : 'Không thể điều phối cấp cứu'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
