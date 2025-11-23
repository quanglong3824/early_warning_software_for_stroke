import 'package:flutter/material.dart';
import '../../../services/health_record_service.dart';
import '../../../services/auth_service.dart';

class ScreenAddHealthRecord extends StatefulWidget {
  const ScreenAddHealthRecord({super.key});

  @override
  State<ScreenAddHealthRecord> createState() => _ScreenAddHealthRecordState();
}

class _ScreenAddHealthRecordState extends State<ScreenAddHealthRecord> {
  final _healthService = HealthRecordService();
  final _authService = AuthService();
  
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _bloodSugarController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final recordId = await _healthService.addHealthRecord(
      userId: userId,
      systolicBP: _systolicController.text.isNotEmpty ? int.tryParse(_systolicController.text) : null,
      diastolicBP: _diastolicController.text.isNotEmpty ? int.tryParse(_diastolicController.text) : null,
      heartRate: _heartRateController.text.isNotEmpty ? int.tryParse(_heartRateController.text) : null,
      bloodSugar: _bloodSugarController.text.isNotEmpty ? double.tryParse(_bloodSugarController.text) : null,
      weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
      height: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
      temperature: _temperatureController.text.isNotEmpty ? double.tryParse(_temperatureController.text) : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (recordId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bản ghi sức khỏe'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi lưu bản ghi'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const borderColor = Color(0xFFDBDFE6);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Thêm bản ghi sức khỏe'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Huyết áp', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _systolicController,
                    hint: 'Tâm thu',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: _InputField(
                    controller: _diastolicController,
                    hint: 'Tâm trương',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Nhịp tim (bpm)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _heartRateController,
              hint: 'Nhập nhịp tim',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Đường huyết (mg/dL)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _bloodSugarController,
              hint: 'Nhập đường huyết',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Cân nặng (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _weightController,
              hint: 'Nhập cân nặng',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Chiều cao (cm)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _heightController,
              hint: 'Nhập chiều cao',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Nhiệt độ (°C)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _temperatureController,
              hint: 'Nhập nhiệt độ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputField(
              controller: _notesController,
              hint: 'Nhập ghi chú (tùy chọn)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveRecord,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Lưu bản ghi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBDFE6)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }
}
