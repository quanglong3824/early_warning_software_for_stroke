import 'package:flutter/material.dart';

class ScreenCreatePrescription extends StatefulWidget {
  const ScreenCreatePrescription({super.key});

  @override
  State<ScreenCreatePrescription> createState() => _ScreenCreatePrescriptionState();
}

class _ScreenCreatePrescriptionState extends State<ScreenCreatePrescription> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _medications = [];
  
  String? _selectedPatient;
  String _diagnosis = '';
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Đơn thuốc'),
        actions: [
          TextButton(
            onPressed: _savePrescription,
            child: const Text('Lưu', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chọn bệnh nhân
            const Text('Bệnh nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text('Chọn bệnh nhân'),
              value: _selectedPatient,
              items: ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C'].map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => _selectedPatient = value),
              validator: (value) => value == null ? 'Vui lòng chọn bệnh nhân' : null,
            ),
            const SizedBox(height: 24),

            // Chẩn đoán
            const Text('Chẩn đoán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Nhập chẩn đoán bệnh',
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 2,
              onChanged: (value) => _diagnosis = value,
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập chẩn đoán' : null,
            ),
            const SizedBox(height: 24),

            // Danh sách thuốc
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách thuốc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm thuốc'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            ..._medications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              return _buildMedicationCard(index, med);
            }),

            if (_medications.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.medication, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chưa có thuốc nào', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Ghi chú
            const Text('Ghi chú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Ghi chú thêm (tùy chọn)',
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(int index, Map<String, dynamic> med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    med['name'] ?? 'Thuốc ${index + 1}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _medications.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Liều lượng: ${med['dosage'] ?? 'Chưa có'}'),
            Text('Thời gian: ${med['duration'] ?? 'Chưa có'}'),
            Text('Hướng dẫn: ${med['instructions'] ?? 'Chưa có'}'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _editMedication(index),
              child: const Text('Chỉnh sửa'),
            ),
          ],
        ),
      ),
    );
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => _MedicationDialog(
        onSave: (med) {
          setState(() => _medications.add(med));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editMedication(int index) {
    showDialog(
      context: context,
      builder: (context) => _MedicationDialog(
        medication: _medications[index],
        onSave: (med) {
          setState(() => _medications[index] = med);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _savePrescription() {
    if (_formKey.currentState!.validate() && _medications.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đơn thuốc thành công!')),
      );
      Navigator.pop(context);
    } else if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 loại thuốc')),
      );
    }
  }
}

class _MedicationDialog extends StatefulWidget {
  final Map<String, dynamic>? medication;
  final Function(Map<String, dynamic>) onSave;

  const _MedicationDialog({this.medication, required this.onSave});

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _durationController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?['name'] ?? '');
    _dosageController = TextEditingController(text: widget.medication?['dosage'] ?? '');
    _durationController = TextEditingController(text: widget.medication?['duration'] ?? '');
    _instructionsController = TextEditingController(text: widget.medication?['instructions'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medication == null ? 'Thêm thuốc' : 'Chỉnh sửa thuốc'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên thuốc'),
            ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Liều lượng (vd: 1 viên/ngày)'),
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Thời gian (vd: 30 ngày)'),
            ),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(labelText: 'Hướng dẫn sử dụng'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave({
                'name': _nameController.text,
                'dosage': _dosageController.text,
                'duration': _durationController.text,
                'instructions': _instructionsController.text,
              });
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
