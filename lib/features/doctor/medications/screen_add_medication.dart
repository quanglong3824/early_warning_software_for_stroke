import 'package:flutter/material.dart';
import '../../../services/medication_service.dart';
import '../../../data/models/medication_models.dart';

class ScreenAddMedication extends StatefulWidget {
  const ScreenAddMedication({super.key});

  @override
  State<ScreenAddMedication> createState() => _ScreenAddMedicationState();
}

class _ScreenAddMedicationState extends State<ScreenAddMedication> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicationService();

  // Controllers for fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'viên');
  final _categoryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _imageUrlCtrl = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final medication = MedicationModel(
      medicationId: '', // will be replaced by service
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      unit: _unitCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      stock: int.parse(_stockCtrl.text.trim()),
      isActive: _isActive,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final id = await _service.addMedication(medication);
    setState(() => _isSaving = false);
    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thuốc thành công'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi thêm thuốc'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thuốc')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên thuốc'),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Giá (VND)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập giá' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(labelText: 'Đơn vị'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập danh mục' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Số lượng tồn'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số lượng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(labelText: 'URL hình ảnh (tùy chọn)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMedication,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thuốc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
