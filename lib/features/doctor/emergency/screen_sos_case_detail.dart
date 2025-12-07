import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/sos_service.dart';
import '../../../services/auth_service.dart';

class ScreenSOSCaseDetail extends StatefulWidget {
  final String? sosId;
  
  const ScreenSOSCaseDetail({super.key, this.sosId});

  @override
  State<ScreenSOSCaseDetail> createState() => _ScreenSOSCaseDetailState();
}

class _ScreenSOSCaseDetailState extends State<ScreenSOSCaseDetail> {
  final SOSService _sosService = SOSService();
  final AuthService _authService = AuthService();
  
  String? _doctorId;
  String? _doctorName;
  SOSCaseDetailModel? _caseDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load doctor info
      final session = await _authService.getUserSession();
      _doctorId = session['userId'];
      _doctorName = session['userName'];

      // Get sosId from arguments or widget
      final sosId = widget.sosId ?? 
          ModalRoute.of(context)?.settings.arguments as String?;
      
      if (sosId == null) {
        setState(() {
          _error = 'Không tìm thấy ID ca SOS';
          _isLoading = false;
        });
        return;
      }

      // Load SOS case detail
      final detail = await _sosService.getSOSCaseDetail(sosId);
      
      setState(() {
        _caseDetail = detail;
        _isLoading = false;
        if (detail == null) {
          _error = 'Không tìm thấy thông tin ca SOS';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Ca SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_caseDetail != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_caseDetail == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final sosCase = _caseDetail!.sosCase;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Alert Card
          _buildEmergencyAlertCard(sosCase),
          const SizedBox(height: 16),
          
          // Patient Info Card
          _buildPatientInfoCard(),
          const SizedBox(height: 16),
          
          // Location Card with Map
          _buildLocationCard(sosCase),
          const SizedBox(height: 16),
          
          // Medical History Card
          if (_caseDetail!.medicalHistory.isNotEmpty) ...[
            _buildMedicalHistoryCard(),
            const SizedBox(height: 16),
          ],
          
          // Emergency Contacts Card
          if (_caseDetail!.emergencyContacts.isNotEmpty) ...[
            _buildEmergencyContactsCard(),
            const SizedBox(height: 16),
          ],
          
          // Emergency Guidelines
          _buildGuidelinesCard(),
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(sosCase),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertCard(SOSCaseModel sosCase) {
    final statusColor = _getStatusColor(sosCase.status);
    final statusText = _getStatusText(sosCase.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: statusColor, size: 28),
              const SizedBox(width: 8),
              Text(
                'CẢNH BÁO KHẨN CẤP',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Trạng thái', statusText, statusColor),
          _buildDetailRow('Thời gian chờ', '${sosCase.waitTimeMinutes} phút'),
          _buildDetailRow('Thời gian tạo', _formatDateTime(sosCase.createdAt)),
          if (sosCase.acknowledgedByName != null)
            _buildDetailRow('Tiếp nhận bởi', sosCase.acknowledgedByName!),
          if (sosCase.notes != null && sosCase.notes!.isNotEmpty)
            _buildDetailRow('Ghi chú', sosCase.notes!),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    final patientInfo = _caseDetail!.patientInfo;
    final sosCase = _caseDetail!.sosCase;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin Bệnh nhân',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Họ tên', sosCase.patientName),
            if (patientInfo != null) ...[
              if (patientInfo['phone'] != null)
                _buildDetailRow('Điện thoại', patientInfo['phone']),
              if (patientInfo['email'] != null)
                _buildDetailRow('Email', patientInfo['email']),
              if (patientInfo['dateOfBirth'] != null)
                _buildDetailRow('Ngày sinh', patientInfo['dateOfBirth']),
              if (patientInfo['gender'] != null)
                _buildDetailRow('Giới tính', patientInfo['gender']),
              if (patientInfo['bloodType'] != null)
                _buildDetailRow('Nhóm máu', patientInfo['bloodType']),
              if (patientInfo['allergies'] != null)
                _buildDetailRow('Dị ứng', patientInfo['allergies'], Colors.orange),
            ],
            const SizedBox(height: 12),
            if (patientInfo?['phone'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _callPatient(patientInfo!['phone']),
                  icon: const Icon(Icons.call),
                  label: const Text('Gọi cho bệnh nhân'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(SOSCaseModel sosCase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Vị trí',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Text(
              sosCase.address,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tọa độ: ${sosCase.latitude.toStringAsFixed(6)}, ${sosCase.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            // Map placeholder - in production, use Google Maps widget
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Bản đồ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openMaps(sosCase.latitude, sosCase.longitude),
                icon: const Icon(Icons.directions),
                label: const Text('Mở Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_information, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử Y tế',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ..._caseDetail!.medicalHistory.take(5).map((record) {
              final recordedAt = record['recordedAt'] as int?;
              final date = recordedAt != null 
                  ? DateTime.fromMillisecondsSinceEpoch(recordedAt)
                  : null;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (date != null)
                      Text(
                        _formatDateTime(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record['systolicBP'] != null && record['diastolicBP'] != null)
                          _buildHealthChip(
                            'HA: ${record['systolicBP']}/${record['diastolicBP']}',
                            Colors.red.shade100,
                          ),
                        if (record['heartRate'] != null)
                          _buildHealthChip(
                            'Nhịp tim: ${record['heartRate']}',
                            Colors.pink.shade100,
                          ),
                        if (record['bloodSugar'] != null)
                          _buildHealthChip(
                            'Đường huyết: ${record['bloodSugar']}',
                            Colors.orange.shade100,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildEmergencyContactsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contacts, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Liên hệ Khẩn cấp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ..._caseDetail!.emergencyContacts.map((contact) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.person, color: Colors.orange),
                ),
                title: Text(contact['name'] ?? 'Không rõ'),
                subtitle: Text(contact['relationship'] ?? ''),
                trailing: contact['phone'] != null
                    ? IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _callPatient(contact['phone']),
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinesCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Hướng dẫn Xử lý',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _buildGuidelineStep('1. Gọi cấp cứu 115 ngay lập tức'),
            _buildGuidelineStep('2. Giữ bệnh nhân nằm yên, đầu hơi cao'),
            _buildGuidelineStep('3. Không cho ăn uống'),
            _buildGuidelineStep('4. Theo dõi nhịp thở và mạch'),
            _buildGuidelineStep('5. Ghi nhận thời gian xuất hiện triệu chứng'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SOSCaseModel sosCase) {
    return Column(
      children: [
        if (sosCase.status == 'pending')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _acknowledgeCase,
              icon: const Icon(Icons.check_circle),
              label: const Text('Tiếp nhận Ca SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (sosCase.status == 'acknowledged') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _dispatchCase,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Điều phối Cấp cứu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resolveCase,
              icon: const Icon(Icons.done_all),
              label: const Text('Hoàn thành Xử lý'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        if (sosCase.status == 'dispatched')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resolveCase,
              icon: const Icon(Icons.done_all),
              label: const Text('Hoàn thành Xử lý'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'dispatched':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
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
      case 'resolved':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _callPatient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
        );
      }
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
    }
  }

  Future<void> _acknowledgeCase() async {
    if (_doctorId == null || _doctorName == null || _caseDetail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tiếp nhận'),
        content: Text('Bạn có chắc muốn tiếp nhận ca SOS của ${_caseDetail!.sosCase.patientName}?'),
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
        _caseDetail!.sosCase.sosId,
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
        if (success) _loadData();
      }
    }
  }

  Future<void> _dispatchCase() async {
    if (_doctorId == null || _caseDetail == null) return;

    final notesController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều phối cấp cứu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Điều phối đội cấp cứu đến hỗ trợ bệnh nhân?'),
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
        _caseDetail!.sosCase.sosId,
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
        if (success) _loadData();
      }
    }
  }

  Future<void> _resolveCase() async {
    if (_doctorId == null || _caseDetail == null) return;

    final resolutionController = TextEditingController();
    final diagnosisController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành xử lý'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập thông tin kết quả xử lý ca SOS:'),
              const SizedBox(height: 16),
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Chẩn đoán',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resolutionController,
                decoration: const InputDecoration(
                  labelText: 'Kết quả xử lý *',
                  border: OutlineInputBorder(),
                  hintText: 'Mô tả kết quả xử lý...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (resolutionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập kết quả xử lý')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _sosService.resolveSOSCase(
        _caseDetail!.sosCase.sosId,
        _doctorId!,
        resolutionController.text.trim(),
        diagnosis: diagnosisController.text.isNotEmpty 
            ? diagnosisController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Đã hoàn thành xử lý ca SOS' 
                : 'Không thể hoàn thành xử lý'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }
}
