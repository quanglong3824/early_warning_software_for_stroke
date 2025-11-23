import 'package:flutter/material.dart';
import '../../../data/models/prescription_models.dart';
import '../../../services/prescription_service.dart';

class ScreenPrescriptionLookup extends StatefulWidget {
  const ScreenPrescriptionLookup({super.key});

  @override
  State<ScreenPrescriptionLookup> createState() => _ScreenPrescriptionLookupState();
}

class _ScreenPrescriptionLookupState extends State<ScreenPrescriptionLookup> {
  final _prescriptionService = PrescriptionService();
  final _codeController = TextEditingController();
  
  PrescriptionModel? _foundPrescription;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchPrescription() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã đơn thuốc';
      });
      return;
    }

    if (code.length < 8) {
      setState(() {
        _errorMessage = 'Mã đơn thuốc phải có ít nhất 8 ký tự';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundPrescription = null;
    });

    try {
      final prescription = await _prescriptionService.getPrescriptionByCode(code);
      
      setState(() {
        _foundPrescription = prescription;
        _isSearching = false;
        if (prescription == null) {
          _errorMessage = 'Không tìm thấy đơn thuốc với mã: $code';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  void _buyMedications() {
    if (_foundPrescription != null) {
      Navigator.pushNamed(
        context,
        '/pharmacy/prescription-purchase',
        arguments: _foundPrescription,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tra cứu đơn thuốc',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.1), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhập mã đơn thuốc',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập mã đơn thuốc từ bác sĩ để xem chi tiết và mua thuốc',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Mã đơn thuốc',
                hintText: 'Ví dụ: ABC12345',
                prefixIcon: const Icon(Icons.medical_services),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _codeController.clear();
                            _foundPrescription = null;
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _searchPrescription(),
            ),
            const SizedBox(height: 16),

            // Search button
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchPrescription,
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Đang tìm...' : 'Tra cứu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // QR Scanner button
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement QR scanner
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng quét QR đang phát triển')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét mã QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Found prescription
            if (_foundPrescription != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tìm thấy đơn thuốc!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Thông tin đơn thuốc',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow('Bác sĩ', _foundPrescription!.doctorName ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Bệnh nhân', _foundPrescription!.patientName ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Số loại thuốc', '${_foundPrescription!.medications.length}'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Tổng tiền',
                      '${_foundPrescription!.totalAmount.toStringAsFixed(0)}đ',
                    ),
                    if (_foundPrescription!.diagnosis != null &&
                        _foundPrescription!.diagnosis!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow('Chẩn đoán', _foundPrescription!.diagnosis!),
                    ],
                    if (_foundPrescription!.isPurchased) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Đơn thuốc này đã được mua',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _foundPrescription!.isPurchased ? null : _buyMedications,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(_foundPrescription!.isPurchased ? 'Đã mua' : 'Mua thuốc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
