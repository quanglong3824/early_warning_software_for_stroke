import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/medication_models.dart';

class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get all medications
  Stream<List<MedicationModel>> getAllMedications() {
    return _db
        .child('medications')
        .orderByChild('isActive')
        .equalTo(true)
        .onValue
        .map((event) {
      final List<MedicationModel> medications = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final medData = Map<String, dynamic>.from(value as Map);
          medData['medicationId'] = key;
          medications.add(MedicationModel.fromJson(medData));
        });
      }
      medications.sort((a, b) => a.name.compareTo(b.name));
      return medications;
    });
  }

  /// Get medication by ID
  Future<MedicationModel?> getMedicationById(String medicationId) async {
    try {
      final snapshot = await _db.child('medications').child(medicationId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['medicationId'] = medicationId;
        return MedicationModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting medication: $e');
      return null;
    }
  }

  /// Search medications by name
  Stream<List<MedicationModel>> searchMedications(String query) {
    return getAllMedications().map((medications) {
      if (query.isEmpty) return medications;
      final lowerQuery = query.toLowerCase();
      return medications.where((med) {
        return med.name.toLowerCase().contains(lowerQuery) ||
               med.category.toLowerCase().contains(lowerQuery) ||
               med.description.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  /// Get medications by category
  Stream<List<MedicationModel>> getMedicationsByCategory(String category) {
    return getAllMedications().map((medications) {
      return medications.where((med) => med.category == category).toList();
    });
  }

  /// Add new medication (Admin only)
  Future<String?> addMedication(MedicationModel medication) async {
    try {
      final medicationRef = _db.child('medications').push();
      final medicationId = medicationRef.key!;
      
      final medWithId = medication.copyWith(
        medicationId: medicationId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await medicationRef.set(medWithId.toJson());
      print('✅ Medication added: ${medication.name}');
      return medicationId;
    } catch (e) {
      print('❌ Error adding medication: $e');
      return null;
    }
  }

  /// Update medication (Admin only)
  Future<bool> updateMedication(String medicationId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _db.child('medications').child(medicationId).update(updates);
      print('✅ Medication updated: $medicationId');
      return true;
    } catch (e) {
      print('❌ Error updating medication: $e');
      return false;
    }
  }

  /// Delete medication (Admin only) - Soft delete
  Future<bool> deleteMedication(String medicationId) async {
    try {
      await _db.child('medications').child(medicationId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Medication deleted (soft): $medicationId');
      return true;
    } catch (e) {
      print('❌ Error deleting medication: $e');
      return false;
    }
  }

  /// Bulk add medications (Admin only)
  Future<int> bulkAddMedications(List<MedicationModel> medications) async {
    int successCount = 0;
    for (final medication in medications) {
      final result = await addMedication(medication);
      if (result != null) successCount++;
    }
    print('✅ Bulk added $successCount/${medications.length} medications');
    return successCount;
  }

  /// Update stock
  Future<bool> updateStock(String medicationId, int newStock) async {
    return updateMedication(medicationId, {'stock': newStock});
  }

  /// Decrease stock (when purchased)
  Future<bool> decreaseStock(String medicationId, int quantity) async {
    try {
      final medication = await getMedicationById(medicationId);
      if (medication == null) return false;
      
      final newStock = medication.stock - quantity;
      if (newStock < 0) {
        print('⚠️ Not enough stock for $medicationId');
        return false;
      }
      
      return updateStock(medicationId, newStock);
    } catch (e) {
      print('❌ Error decreasing stock: $e');
      return false;
    }
  }

  /// Get all categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _db.child('medications').get();
      final Set<String> categories = {};
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final medData = Map<String, dynamic>.from(value as Map);
          if (medData['isActive'] == true) {
            categories.add(medData['category'] as String? ?? 'Khác');
          }
        });
      }
      
      final categoryList = categories.toList()..sort();
      return categoryList;
    } catch (e) {
      print('❌ Error getting categories: $e');
      return [];
    }
  }
}
