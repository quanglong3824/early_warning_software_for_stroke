import 'package:flutter/material.dart';
import '../../../data/models/medication_models.dart';
import '../../../data/bulk_medications_data.dart';
import '../../../services/medication_service.dart';
import 'screen_add_edit_medication.dart';

class ScreenAdminMedications extends StatefulWidget {
  const ScreenAdminMedications({super.key});

  @override
  State<ScreenAdminMedications> createState() => _ScreenAdminMedicationsState();
}

class _ScreenAdminMedicationsState extends State<ScreenAdminMedications> {
  final _medicationService = MedicationService();
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bulkImportMedications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import thuốc hàng loạt'),
        content: Text('Bạn có muốn import ${BulkMedicationsData.defaultMedications.length} loại thuốc vào hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isImporting = true);

    try {
      final count = await _medicationService.bulkAddMedications(
        BulkMedicationsData.defaultMedications,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã import thành công $count loại thuốc'),
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
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _addMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScreenAddEditMedication(),
      ),
    );
    // Refresh list if medication was added
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editMedication(MedicationModel medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenAddEditMedication(
          medication: medication,
        ),
      ),
    );
    // Refresh list if medication was updated
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteMedication(MedicationModel medication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thuốc'),
        content: Text('Bạn có chắc muốn xóa "${medication.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _medicationService.deleteMedication(medication.medicationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã xóa thuốc' : 'Lỗi khi xóa thuốc'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Quản lý thuốc',
          style: TextStyle(color: Color(0xFF111318), fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file, color: primary),
              onPressed: _bulkImportMedications,
              tooltip: 'Import thuốc hàng loạt',
            ),
          IconButton(
            icon: const Icon(Icons.add, color: primary),
            onPressed: _addMedication,
            tooltip: 'Thêm thuốc',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thuốc...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F8),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<String>>(
                  future: _medicationService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Tất cả'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Medications list
          Expanded(
            child: StreamBuilder<List<MedicationModel>>(
              stream: _selectedCategory == null
                  ? _medicationService.getAllMedications()
                  : _medicationService.getMedicationsByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                var medications = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final lowerQuery = _searchQuery.toLowerCase();
                  medications = medications.where((med) {
                    return med.name.toLowerCase().contains(lowerQuery) ||
                           med.category.toLowerCase().contains(lowerQuery);
                  }).toList();
                }

                if (medications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có thuốc nào',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.medication, color: primary),
                        ),
                        title: Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(med.category),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${med.price.toStringAsFixed(0)}đ/${med.unit}',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('Tồn kho: ${med.stock}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editMedication(med);
                            } else if (value == 'delete') {
                              _deleteMedication(med);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedication,
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm thuốc'),
      ),
    );
  }
}
