import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/health_record_model.dart';
import '../../../services/appointment_service.dart';

class ScreenAppointmentRequestDetail extends StatefulWidget {
  final String appointmentId;

  const ScreenAppointmentRequestDetail({
    super.key,
    required this.appointmentId,
  });

  @override
  State<ScreenAppointmentRequestDetail> createState() =>
      _ScreenAppointmentRequestDetailState();
}

class _ScreenAppointmentRequestDetailState
    extends State<ScreenAppointmentRequestDetail> {
  final AppointmentService _appointmentService = AppointmentService();
  AppointmentDetailModel? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetail();
  }

  Future<void> _loadAppointmentDetail() async {
    try {
      final detail = await _appointmentService.getAppointmentDetail(widget.appointmentId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Yêu cầu Lịch hẹn')),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointmentDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_detail == null) {
      return const Center(child: Text('Không tìm thấy thông tin lịch hẹn'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfoSection(),
          const SizedBox(height: 24),
          _buildAppointmentInfoSection(),
          const SizedBox(height: 24),
          _buildMedicalHistorySection(),
          const SizedBox(height: 24),
          _buildHealthRecordsSection(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    final patient = _detail!.patient;
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (patient != null) ...[
              _buildInfoRow('Họ tên:', patient.name),
              if (patient.phone != null)
                _buildInfoRow('Số điện thoại:', patient.phone!),
              if (patient.email != null)
                _buildInfoRow('Email:', patient.email!),
              if (patient.gender != null)
                _buildInfoRow('Giới tính:', _formatGender(patient.gender!)),
              if (patient.dateOfBirth != null)
                _buildInfoRow('Ngày sinh:',
                    DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!)),
              if (patient.address != null)
                _buildInfoRow('Địa chỉ:', patient.address!),
            ] else ...[
              const Text('Không có thông tin bệnh nhân',
                  style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentInfoSection() {
    final appointment = _detail!.appointment;
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(appointment.appointmentTime);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin Lịch hẹn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Thời gian mong muốn:',
                '${DateFormat('HH:mm').format(dateTime)} - ${DateFormat('dd/MM/yyyy').format(dateTime)}'),
            _buildInfoRow('Lý do khám:', appointment.reason),
            if (appointment.location.isNotEmpty)
              _buildInfoRow('Địa điểm:', appointment.location),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildInfoRow('Ghi chú:', appointment.notes!),
            _buildInfoRow('Ngày tạo yêu cầu:',
                DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(appointment.createdAt))),
          ],
        ),
      ),
    );
  }


  Widget _buildMedicalHistorySection() {
    final previousAppointments = _detail!.previousAppointments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử Khám bệnh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (previousAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có lịch sử khám với bác sĩ này',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: previousAppointments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final apt = previousAppointments[index];
                  final dateTime =
                      DateTime.fromMillisecondsSinceEpoch(apt.appointmentTime);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.medical_services,
                          color: Colors.blue, size: 20),
                    ),
                    title: Text(apt.reason),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: _buildStatusChip(apt.status),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecordsSection() {
    final healthRecords = _detail!.healthRecords;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Hồ sơ Sức khỏe Gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (healthRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có hồ sơ sức khỏe',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: healthRecords.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final record = healthRecords[index];
                  final dateTime =
                      DateTime.fromMillisecondsSinceEpoch(record.recordedAt);
                  return _buildHealthRecordItem(record, dateTime);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecordItem(HealthRecordModel record, DateTime dateTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (record.systolicBP != null && record.diastolicBP != null)
                _buildHealthMetric(
                  'Huyết áp',
                  '${record.systolicBP}/${record.diastolicBP}',
                  'mmHg',
                  _getBPColor(record.systolicBP!, record.diastolicBP!),
                ),
              if (record.heartRate != null)
                _buildHealthMetric(
                  'Nhịp tim',
                  '${record.heartRate}',
                  'bpm',
                  _getHeartRateColor(record.heartRate!),
                ),
              if (record.bloodSugar != null)
                _buildHealthMetric(
                  'Đường huyết',
                  '${record.bloodSugar}',
                  'mg/dL',
                  Colors.purple,
                ),
              if (record.temperature != null)
                _buildHealthMetric(
                  'Nhiệt độ',
                  '${record.temperature}',
                  '°C',
                  Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(
      String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    final appointment = _detail!.appointment;
    
    // Chỉ hiển thị buttons nếu lịch hẹn đang ở trạng thái pending
    if (appointment.status != 'pending') {
      return Card(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Yêu cầu này đã được xử lý (${_getStatusText(appointment.status)})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showRejectDialog,
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmAppointment,
            icon: const Icon(Icons.check),
            label: const Text('Xác nhận'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lịch hẹn'),
        content: Text(
            'Bạn có chắc muốn xác nhận lịch hẹn với ${_detail!.patient?.name ?? "bệnh nhân"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _appointmentService
          .confirmAppointment(_detail!.appointment.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã xác nhận lịch hẹn'
                : 'Không thể xác nhận lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối lịch hẹn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Bạn có chắc muốn từ chối lịch hẹn với ${_detail!.patient?.name ?? "bệnh nhân"}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _appointmentService.rejectAppointment(
          _detail!.appointment.appointmentId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Đã từ chối lịch hẹn' : 'Không thể từ chối lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Đã từ chối';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chờ xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return status;
    }
  }

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return gender;
    }
  }

  Color _getBPColor(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return Colors.red;
    if (systolic < 90 || diastolic < 60) return Colors.orange;
    return Colors.green;
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate > 100) return Colors.red;
    if (heartRate < 60) return Colors.orange;
    return Colors.green;
  }
}
