import 'package:flutter/material.dart';
import '../../../data/models/medication_models.dart';
import '../../../data/models/prescription_models.dart';
import '../../../services/medication_service.dart';
import '../../../services/prescription_service.dart';
import '../../../services/auth_service.dart';

class ScreenCreatePrescription extends StatefulWidget {
  final String userId;
  final String patientName;

  const ScreenCreatePrescription({
    super.key,
    required this.userId,
    required this.patientName,
  });

  @override
  State<ScreenCreatePrescription> createState() => _ScreenCreatePrescriptionState();
}

class _ScreenCreatePrescriptionState extends State<ScreenCreatePrescription> {
  final _formKey = GlobalKey<FormState>();
  final _medicationService = MedicationService();
  final _prescriptionService = PrescriptionService();
  final _authService = AuthService();

  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  
  // List of medications to prescribe
  final List<PrescriptionMedicationModel> _prescribedMedications = [];
  
  bool _isSaving = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addMedication(MedicationModel medication) {
    // Check if already added
    if (_prescribedMedications.any((m) => m.medicationId == medication.medicationId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medication.name} đã có trong danh sách')),
      );
      return;
    }

    setState(() {
      _prescribedMedications.add(PrescriptionMedicationModel(
        medicationId: medication.medicationId,
        medicationName: medication.name,
        dosage: '',
        frequency: '',
        duration: '',
        quantity: 1,
        price: medication.price,
        instructions: '',
      ));
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _prescribedMedications.removeAt(index);
    });
  }

  void _updateMedication(int index, PrescriptionMedicationModel updatedMed) {
    setState(() {
      _prescribedMedications[index] = updatedMed;
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prescribedMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 loại thuốc')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final doctorId = await _authService.getUserId();
      if (doctorId == null) throw Exception('Lỗi xác thực bác sĩ');

      // TODO: Get doctor name properly (mock for now or fetch from service)
      const doctorName = 'Bác sĩ'; 

      final prescriptionId = await _prescriptionService.createPrescription(
        doctorId: doctorId,
        doctorName: doctorName,
        userId: widget.userId,
        patientName: widget.patientName,
        medications: _prescribedMedications,
        diagnosis: _diagnosisController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (prescriptionId != null) {
        if (mounted) {
          // Show success dialog with code
          // We need to fetch the code, but createPrescription returns ID. 
          // However, createPrescription logs the code. 
          // Ideally createPrescription should return the code or the object.
          // For now, let's just show success and pop.
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo đơn thuốc thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Không thể tạo đơn thuốc');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddMedicationSheet(onSelect: _addMedication),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kê đơn thuốc'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePrescription,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bệnh nhân',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111318),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Diagnosis
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Chẩn đoán',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Vui lòng nhập chẩn đoán' : null,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú / Lời dặn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Medications Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách thuốc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicationSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thuốc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Medications List
              if (_prescribedMedications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có thuốc nào được thêm',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _prescribedMedications.length,
                  itemBuilder: (context, index) {
                    return _MedicationInputCard(
                      medication: _prescribedMedications[index],
                      onRemove: () => _removeMedication(index),
                      onUpdate: (updated) => _updateMedication(index, updated),
                    );
                  },
                ),
                
              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationInputCard extends StatefulWidget {
  final PrescriptionMedicationModel medication;
  final VoidCallback onRemove;
  final Function(PrescriptionMedicationModel) onUpdate;

  const _MedicationInputCard({
    required this.medication,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_MedicationInputCard> createState() => _MedicationInputCardState();
}

class _MedicationInputCardState extends State<_MedicationInputCard> {
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _durationController;
  late TextEditingController _quantityController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _frequencyController = TextEditingController(text: widget.medication.frequency);
    _durationController = TextEditingController(text: widget.medication.duration);
    _quantityController = TextEditingController(text: widget.medication.quantity.toString());
    _instructionsController = TextEditingController(text: widget.medication.instructions);
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _quantityController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _updateModel() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final updated = widget.medication.copyWith(
      dosage: _dosageController.text,
      frequency: _frequencyController.text,
      duration: _durationController.text,
      quantity: quantity,
      instructions: _instructionsController.text,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
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
                    widget.medication.medicationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Liều lượng',
                      hintText: 'VD: 500mg',
                      isDense: true,
                    ),
                    onChanged: (_) => _updateModel(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateModel(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _frequencyController,
                    decoration: const InputDecoration(
                      labelText: 'Tần suất',
                      hintText: 'VD: Sáng 1, Chiều 1',
                      isDense: true,
                    ),
                    onChanged: (_) => _updateModel(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian',
                      hintText: 'VD: 5 ngày',
                      isDense: true,
                    ),
                    onChanged: (_) => _updateModel(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Hướng dẫn sử dụng',
                hintText: 'VD: Uống sau ăn',
                isDense: true,
              ),
              onChanged: (_) => _updateModel(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Thành tiền: ${(widget.medication.price * (int.tryParse(_quantityController.text) ?? 1)).toStringAsFixed(0)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  final Function(MedicationModel) onSelect;

  const _AddMedicationSheet({required this.onSelect});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _medicationService = MedicationService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thêm thuốc',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thuốc...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<MedicationModel>>(
              stream: _medicationService.searchMedications(_query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final medications = snapshot.data ?? [];
                
                if (medications.isEmpty) {
                  return const Center(child: Text('Không tìm thấy thuốc'));
                }

                return ListView.separated(
                  itemCount: medications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return ListTile(
                      title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${med.category} • ${med.price.toStringAsFixed(0)}đ'),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF135BEC)),
                      onTap: () {
                        widget.onSelect(med);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
