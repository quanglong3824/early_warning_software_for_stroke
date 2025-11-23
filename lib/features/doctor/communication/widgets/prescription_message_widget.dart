import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/chat_models.dart';
import '../../../../data/models/prescription_models.dart';
import '../../../../services/prescription_service.dart';

class PrescriptionMessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isDoctor;

  const PrescriptionMessageWidget({
    super.key,
    required this.message,
    this.isDoctor = false,
  });

  @override
  State<PrescriptionMessageWidget> createState() => _PrescriptionMessageWidgetState();
}

class _PrescriptionMessageWidgetState extends State<PrescriptionMessageWidget> {
  final _prescriptionService = PrescriptionService();
  PrescriptionModel? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    if (widget.message.prescriptionId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prescription = await _prescriptionService.getPrescription(widget.message.prescriptionId!);
    if (mounted) {
      setState(() {
        _prescription = prescription;
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_prescription != null) {
      Clipboard.setData(ClipboardData(text: _prescription!.prescriptionCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã copy mã đơn thuốc')),
      );
    }
  }

  void _viewDetails() {
    if (_prescription != null) {
      Navigator.pushNamed(
        context,
        '/doctor/prescription-detail',
        arguments: _prescription,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const success = Color(0xFF10B981);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Đang tải đơn thuốc...'),
          ],
        ),
      );
    }

    if (_prescription == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text('Không tìm thấy đơn thuốc')),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.1), success.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn thuốc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                      Text(
                        'Prescription',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_prescription!.isPurchased)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Đã mua',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescription Code
                Row(
                  children: [
                    const Icon(Icons.qr_code, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Mã đơn:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          _prescription!.prescriptionCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF111318),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: _copyCode,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Medications count
                Row(
                  children: [
                    const Icon(Icons.medication, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${_prescription!.medications.length} loại thuốc',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Total amount
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng: ${_prescription!.totalAmount.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111318),
                      ),
                    ),
                  ],
                ),

                if (_prescription!.diagnosis != null && _prescription!.diagnosis!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chẩn đoán:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _prescription!.diagnosis!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Xem chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                if (!widget.isDoctor) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _prescription!.isPurchased
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/pharmacy/prescription-detail',
                                arguments: _prescription,
                              );
                            },
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: Text(_prescription!.isPurchased ? 'Đã mua' : 'Mua thuốc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
