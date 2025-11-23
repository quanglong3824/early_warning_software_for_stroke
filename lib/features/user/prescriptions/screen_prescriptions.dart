import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/prescription_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/prescription_models.dart';

class ScreenPrescriptions extends StatefulWidget {
  const ScreenPrescriptions({super.key});

  @override
  State<ScreenPrescriptions> createState() => _ScreenPrescriptionsState();
}

class _ScreenPrescriptionsState extends State<ScreenPrescriptions> {
  final _prescriptionService = PrescriptionService();
  final _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    setState(() => _userId = userId);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);
    const primary = Color(0xFF135BEC);

    if (_userId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Đơn thuốc của tôi'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Đơn thuốc của tôi',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: _prescriptionService.getUserPrescriptions(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có đơn thuốc nào',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = prescriptions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PrescriptionItem(
                  title: 'Đơn thuốc ngày ${_formatDate(prescription.prescribedDate)}',
                  subtitle: '${prescription.doctorName ?? "Bác sĩ"} - ${prescription.items.length} loại thuốc',
                  status: prescription.status,
                  itemCount: prescription.items.length,
                  onTap: () {
                    // TODO: Navigate to prescription detail
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PrescriptionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final int itemCount;
  final VoidCallback? onTap;

  const _PrescriptionItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.itemCount,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'active':
        return 'Đang dùng';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.medication, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF616F89),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}