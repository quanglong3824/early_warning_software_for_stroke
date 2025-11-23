import 'package:flutter/material.dart';
import '../../../../data/models/medication_models.dart';
import '../../../../data/models/prescription_models.dart';
import '../../../../services/medication_service.dart';
import '../../../../services/prescription_service.dart';
import '../../../../services/chat_service.dart';

class CreatePrescriptionDialog extends StatefulWidget {
  final String conversationId;
  final String userId;
  final String patientName;
  final String doctorId;
  final String doctorName;

  const CreatePrescriptionDialog({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<CreatePrescriptionDialog> createState() => _CreatePrescriptionDialogState();
}

class _CreatePrescriptionDialogState extends State<CreatePrescriptionDialog> {
  final _medicationService = MedicationService();
  final _prescriptionService = PrescriptionService();
  final _chatService = ChatService();
  
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<MedicationModel> _allMedications = [];
  List<MedicationModel> _filteredMedications = [];
  List<PrescriptionMedicationModel> _selectedMedications = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    _medicationService.getAllMedications().listen((medications) {
      if (mounted) {
        setState(() {
          _allMedications = medications;
          _filteredMedications = medications;
          _isLoading = false;
        });
      }
    });
  }

  void _filterMedications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedications = _allMedications;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredMedications = _allMedications.where((med) {
          return med.name.toLowerCase().contains(lowerQuery) ||
                 med.category.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _addMedication(MedicationModel medication) {
    showDialog(
      context: context,
      builder: (context) => _MedicationDetailDialog(
        medication: medication,
        onAdd: (prescriptionMed) {
          setState(() {
            _selectedMedications.add(prescriptionMed);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeMedication(int index) {
    setState(() {
      _selectedMedications.removeAt(index);
    });
  }

  Future<void> _createPrescription() async {
    if (_selectedMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 loại thuốc')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Create prescription
      final prescriptionId = await _prescriptionService.createPrescription(
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        userId: widget.userId,
        patientName: widget.patientName,
        medications: _selectedMedications,
        diagnosis: _diagnosisController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (prescriptionId == null) {
        throw Exception('Không thể tạo đơn thuốc');
      }

      // Get prescription to get the code
      final prescription = await _prescriptionService.getPrescription(prescriptionId);
      if (prescription == null) {
        throw Exception('Không tìm thấy đơn thuốc');
      }

      // Send prescription message to chat
      await _chatService.sendPrescriptionMessage(
        conversationId: widget.conversationId,
        senderId: widget.doctorId,
        senderName: widget.doctorName,
        prescriptionId: prescriptionId,
        prescriptionCode: prescription.prescriptionCode,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo đơn thuốc - Mã: ${prescription.prescriptionCode}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.medical_services, color: primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tạo đơn thuốc',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bệnh nhân: ${widget.patientName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),

            // Diagnosis
            TextField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Chẩn đoán',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Selected medications
            if (_selectedMedications.isNotEmpty) ...[
              const Text(
                'Thuốc đã chọn:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedMedications.length,
                  itemBuilder: (context, index) {
                    final med = _selectedMedications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        title: Text(med.medicationName, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${med.dosage} - ${med.frequency}', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _removeMedication(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search medications
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm thuốc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterMedications,
            ),
            const SizedBox(height: 12),

            // Medications list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMedications.isEmpty
                      ? const Center(child: Text('Không tìm thấy thuốc'))
                      : ListView.builder(
                          itemCount: _filteredMedications.length,
                          itemBuilder: (context, index) {
                            final med = _filteredMedications[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication, color: primary),
                                ),
                                title: Text(med.name),
                                subtitle: Text('${med.category} - ${med.price.toStringAsFixed(0)}đ/${med.unit}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: primary),
                                  onPressed: () => _addMedication(med),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Notes
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createPrescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Tạo đơn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationDetailDialog extends StatefulWidget {
  final MedicationModel medication;
  final Function(PrescriptionMedicationModel) onAdd;

  const _MedicationDetailDialog({
    required this.medication,
    required this.onAdd,
  });

  @override
  State<_MedicationDetailDialog> createState() => _MedicationDetailDialogState();
}

class _MedicationDetailDialogState extends State<_MedicationDetailDialog> {
  final _dosageController = TextEditingController(text: '1 viên');
  final _frequencyController = TextEditingController(text: 'Sáng 1, Trưa 1, Tối 1');
  final _durationController = TextEditingController(text: '30 ngày');
  final _instructionsController = TextEditingController(text: 'Uống sau ăn');
  final _quantityController = TextEditingController(text: '90');

  @override
  void dispose() {
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _add() {
    final prescriptionMed = PrescriptionMedicationModel(
      medicationId: widget.medication.medicationId,
      medicationName: widget.medication.name,
      dosage: _dosageController.text,
      frequency: _frequencyController.text,
      duration: _durationController.text,
      instructions: _instructionsController.text,
      price: widget.medication.price,
      quantity: int.tryParse(_quantityController.text) ?? 1,
    );
    widget.onAdd(prescriptionMed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medication.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Liều lượng'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(labelText: 'Tần suất'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Thời gian'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(labelText: 'Hướng dẫn'),
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
          onPressed: _add,
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
