import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/prescription_models.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get all prescriptions for a user
  Stream<List<PrescriptionModel>> getUserPrescriptions(String userId) {
    return _db
        .child('prescriptions')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<PrescriptionModel> prescriptions = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final prescriptionData = Map<String, dynamic>.from(value as Map);
          prescriptions.add(PrescriptionModel.fromJson(prescriptionData));
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
