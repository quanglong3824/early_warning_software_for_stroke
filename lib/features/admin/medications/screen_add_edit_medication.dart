import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/medication_models.dart';
import '../../../services/medication_service.dart';

class ScreenAddEditMedication extends StatefulWidget {
  final MedicationModel? medication; // null = add mode, non-null = edit mode

  const ScreenAddEditMedication({
    super.key,
    this.medication,
  });

  @override
  State<ScreenAddEditMedication> createState() => _ScreenAddEditMedicationState();
}

class _ScreenAddEditMedicationState extends State<ScreenAddEditMedication> {
  final _formKey = GlobalKey<FormState>();
  final _medicationService = MedicationService();
  
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    
    _nameController = TextEditingController(text: med?.name ?? '');
    _categoryController = TextEditingController(text: med?.category ?? '');
    _descriptionController = TextEditingController(text: med?.description ?? '');
    _priceController = TextEditingController(text: med?.price.toString() ?? '');
    _stockController = TextEditingController(text: med?.stock.toString() ?? '');
    _unitController = TextEditingController(text: med?.unit ?? 'viên');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final medication = MedicationModel(
        medicationId: widget.medication?.medicationId ?? '',
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        unit: _unitController.text.trim(),
        isActive: true,
        createdAt: widget.medication?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      );

      bool success;
      if (widget.medication == null) {
        // Add mode
        final result = await _medicationService.addMedication(medication);
        success = result != null;
      } else {
        // Edit mode
        success = await _medicationService.updateMedication(
          widget.medication!.medicationId,
          medication.toJson(),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medication == null ? 'Đã thêm thuốc' : 'Đã cập nhật thuốc'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi lưu thuốc'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    final isEditMode = widget.medication != null;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Chỉnh sửa thuốc' : 'Thêm thuốc mới',
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            _buildSection(
              'Thông tin cơ bản',
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Tên thuốc',
                  icon: Icons.medication,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _categoryController,
                  label: 'Danh mục',
                  icon: Icons.category,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  icon: Icons.description,
                  maxLines: 3,
                  required: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Price & Stock
            _buildSection(
              'Giá & Tồn kho',
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Giá (đ)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _unitController,
                        label: 'Đơn vị',
                        icon: Icons.scale,
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _stockController,
                  label: 'Số lượng tồn kho',
                  icon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveMedication,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditMode ? 'Cập nhật' : 'Thêm thuốc',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFFF6F6F8),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập $label';
              }
              if (keyboardType == TextInputType.number) {
                if (double.tryParse(value) == null) {
                  return 'Vui lòng nhập số hợp lệ';
                }
              }
              return null;
            }
          : null,
    );
  }
}
