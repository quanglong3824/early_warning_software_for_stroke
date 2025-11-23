import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/prescription_models.dart';
import '../data/models/medication_models.dart';
import 'enhanced_notification_service.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  /// Generate unique prescription code (8 characters: letters + numbers)
  String generatePrescriptionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude similar chars
    final random = Random();
    final code = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    return code;
  }

  /// Check if prescription code exists
  Future<bool> _codeExists(String code) async {
    try {
      final snapshot = await _db
          .child('prescriptions')
          .orderByChild('prescriptionCode')
          .equalTo(code)
          .limitToFirst(1)
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Generate unique prescription code
  Future<String> generateUniquePrescriptionCode() async {
    String code;
    int attempts = 0;
    do {
      code = generatePrescriptionCode();
      attempts++;
      if (attempts > 10) {
        // Fallback: add timestamp
        code = '$code${DateTime.now().millisecondsSinceEpoch % 100}';
        break;
      }
    } while (await _codeExists(code));
    return code;
  }

  /// Create prescription with auto-generated code
  Future<String?> createPrescription({
    required String doctorId,
    required String doctorName,
    required String userId,
    required String patientName,
    required List<PrescriptionMedicationModel> medications,
    String? diagnosis,
    String? notes,
  }) async {
    try {
      final prescriptionRef = _db.child('prescriptions').push();
      final prescriptionId = prescriptionRef.key!;
      final prescriptionCode = await generateUniquePrescriptionCode();
      
      // Calculate total amount
      final totalAmount = medications.fold<double>(
        0,
        (sum, med) => sum + med.totalPrice,
      );

      final prescription = PrescriptionModel(
        prescriptionId: prescriptionId,
        prescriptionCode: prescriptionCode,
        userId: userId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        diagnosis: diagnosis,
        medications: medications,
        status: 'active',
        prescribedDate: DateTime.now().millisecondsSinceEpoch,
        notes: notes,
        totalAmount: totalAmount,
        isPurchased: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await prescriptionRef.set(prescription.toJson());
      
      // Also index by code for quick lookup
      await _db.child('prescription_codes').child(prescriptionCode).set(prescriptionId);
      
      // Send notification to user
      await _notificationService.createNotification(
        userId: userId,
        type: 'prescription',
        title: 'Đơn thuốc mới',
        message: 'Bác sĩ $doctorName vừa kê đơn thuốc mới cho bạn. Mã đơn: $prescriptionCode',
        data: {
          'prescriptionId': prescriptionId,
          'prescriptionCode': prescriptionCode,
          'doctorId': doctorId,
        },
      );
      
      print('✅ Prescription created: $prescriptionCode');
      return prescriptionId;
    } catch (e) {
      print('❌ Error creating prescription: $e');
      return null;
    }
  }

  /// Get prescription by code
  Future<PrescriptionModel?> getPrescriptionByCode(String code) async {
    try {
      // First get prescription ID from code index
      final codeSnapshot = await _db.child('prescription_codes').child(code).get();
      if (!codeSnapshot.exists) {
        print('⚠️ Prescription code not found: $code');
        return null;
      }

      final prescriptionId = codeSnapshot.value as String;
      return getPrescription(prescriptionId);
    } catch (e) {
      print('❌ Error getting prescription by code: $e');
      return null;
    }
  }

  /// Mark prescription as purchased
  Future<bool> markAsPurchased(String prescriptionId, String orderId) async {
    try {
      await _db.child('prescriptions').child(prescriptionId).update({
        'isPurchased': true,
        'purchaseDate': DateTime.now().millisecondsSinceEpoch,
        'orderId': orderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Prescription marked as purchased: $prescriptionId');
      return true;
    } catch (e) {
      print('❌ Error marking prescription as purchased: $e');
      return false;
    }
  }

  /// Get all prescriptions for a user
  Stream<List<PrescriptionModel>> getUserPrescriptions(String userId) {
    return _db
        .child('prescriptions')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<PrescriptionModel> prescriptions = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final dynamic value = event.snapshot.value;
        Map<dynamic, dynamic> data = {};
        
        if (value is Map) {
          data = value;
        } else if (value is List) {
           for (int i = 0; i < value.length; i++) {
             if (value[i] != null) {
               data[i.toString()] = value[i];
             }
           }
        }

        data.forEach((key, value) {
          if (value == null) return;
          if (value is Map) {
             final prescriptionData = Map<String, dynamic>.from(value);
             prescriptions.add(PrescriptionModel.fromJson(prescriptionData));
          }
        });
      }
      prescriptions.sort((a, b) => b.prescribedDate.compareTo(a.prescribedDate));
      return prescriptions;
    });
  }

  /// Get active prescriptions
  Stream<List<PrescriptionModel>> getActivePrescriptions(String userId) {
    return getUserPrescriptions(userId).map((prescriptions) {
      return prescriptions.where((p) => p.status == 'active').toList();
    });
  }

  /// Get prescription by ID
  Future<PrescriptionModel?> getPrescription(String prescriptionId) async {
    try {
      final snapshot = await _db.child('prescriptions').child(prescriptionId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return PrescriptionModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting prescription: $e');
      return null;
    }
  }

  /// Update prescription status
  Future<bool> updatePrescriptionStatus(String prescriptionId, String status) async {
    try {
      await _db.child('prescriptions').child(prescriptionId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error updating prescription status: $e');
      return false;
    }
  }
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get all reminders for a user
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _db
        .child('reminders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<ReminderModel> reminders = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final reminderData = Map<String, dynamic>.from(value as Map);
          reminders.add(ReminderModel.fromJson(reminderData));
        });
      }
      return reminders;
    });
  }

  /// Get active reminders
  Stream<List<ReminderModel>> getActiveReminders(String userId) {
    return getUserReminders(userId).map((reminders) {
      return reminders.where((r) => r.isActive).toList();
    });
  }

  /// Create reminder
  Future<String?> createReminder({
    required String userId,
    required String prescriptionId,
    required String medicationName,
    required String dosage,
    required List<String> times,
    int? startDate,
    int? endDate,
  }) async {
    try {
      final reminderRef = _db.child('reminders').push();
      final reminderId = reminderRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final reminder = ReminderModel(
        reminderId: reminderId,
        userId: userId,
        prescriptionId: prescriptionId,
        medicationName: medicationName,
        dosage: dosage,
        times: times,
        isActive: true,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
      );

      await reminderRef.set(reminder.toJson());
      return reminderId;
    } catch (e) {
      print('Error creating reminder: $e');
      return null;
    }
  }

  /// Toggle reminder active status
  Future<bool> toggleReminder(String reminderId, bool isActive) async {
    try {
      await _db.child('reminders').child(reminderId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      print('Error toggling reminder: $e');
      return false;
    }
  }

  /// Update reminder
  Future<bool> updateReminder({
    required String reminderId,
    String? medicationName,
    String? dosage,
    List<String>? times,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': ServerValue.timestamp,
      };
      
      if (medicationName != null) updates['medicationName'] = medicationName;
      if (dosage != null) updates['dosage'] = dosage;
      if (times != null) updates['times'] = times;
      if (isActive != null) updates['isActive'] = isActive;

      await _db.child('reminders').child(reminderId).update(updates);
      return true;
    } catch (e) {
      print('Error updating reminder: $e');
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _db.child('reminders').child(reminderId).remove();
      return true;
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }
}
