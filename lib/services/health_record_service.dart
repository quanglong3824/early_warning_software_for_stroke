import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../data/models/health_record_model.dart';

class HealthRecordService {
  static final HealthRecordService _instance = HealthRecordService._internal();
  factory HealthRecordService() => _instance;
  HealthRecordService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();

  /// Get all health records for a user
  Stream<List<HealthRecordModel>> getHealthRecords(String userId) {
    return _db
        .child('health_records')
        .child(userId)
        .orderByChild('recordedAt')
        .onValue
        .map((event) {
      final List<HealthRecordModel> records = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final recordData = Map<String, dynamic>.from(value as Map);
          records.add(HealthRecordModel.fromJson(recordData));
        });
      }
      // Sort by recordedAt descending (newest first)
      records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return records;
    });
  }

  /// Get latest health record
  Future<HealthRecordModel?> getLatestHealthRecord(String userId) async {
    try {
      final snapshot = await _db
          .child('health_records')
          .child(userId)
          .orderByChild('recordedAt')
          .limitToLast(1)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final firstKey = data.keys.first;
        final recordData = Map<String, dynamic>.from(data[firstKey] as Map);
        return HealthRecordModel.fromJson(recordData);
      }
      return null;
    } catch (e) {
      print('Error getting latest health record: $e');
      return null;
    }
  }

  /// Add new health record
  Future<String?> addHealthRecord({
    required String userId,
    int? systolicBP,
    int? diastolicBP,
    int? heartRate,
    double? bloodSugar,
    double? weight,
    double? height,
    double? temperature,
    String? notes,
  }) async {
    try {
      final recordRef = _db.child('health_records').child(userId).push();
      final recordId = recordRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final record = HealthRecordModel(
        id: recordId,
        userId: userId,
        recordedAt: now,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        heartRate: heartRate,
        bloodSugar: bloodSugar,
        weight: weight,
        height: height,
        temperature: temperature,
        notes: notes,
        createdAt: now,
      );

      await recordRef.set(record.toJson());
      return recordId;
    } catch (e) {
      print('Error adding health record: $e');
      return null;
    }
  }

  /// Update health record
  Future<bool> updateHealthRecord({
    required String userId,
    required String recordId,
    int? systolicBP,
    int? diastolicBP,
    int? heartRate,
    double? bloodSugar,
    double? weight,
    double? height,
    double? temperature,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (systolicBP != null) updates['systolicBP'] = systolicBP;
      if (diastolicBP != null) updates['diastolicBP'] = diastolicBP;
      if (heartRate != null) updates['heartRate'] = heartRate;
      if (bloodSugar != null) updates['bloodSugar'] = bloodSugar;
      if (weight != null) updates['weight'] = weight;
      if (height != null) updates['height'] = height;
      if (temperature != null) updates['temperature'] = temperature;
      if (notes != null) updates['notes'] = notes;

      await _db
          .child('health_records')
          .child(userId)
          .child(recordId)
          .update(updates);
      return true;
    } catch (e) {
      print('Error updating health record: $e');
      return false;
    }
  }

  /// Delete health record
  Future<bool> deleteHealthRecord(String userId, String recordId) async {
    try {
      await _db
          .child('health_records')
          .child(userId)
          .child(recordId)
          .remove();
      return true;
    } catch (e) {
      print('Error deleting health record: $e');
      return false;
    }
  }

  /// Get health statistics
  Future<Map<String, dynamic>> getHealthStats(String userId) async {
    try {
      final snapshot = await _db
          .child('health_records')
          .child(userId)
          .orderByChild('recordedAt')
          .limitToLast(30)
          .get();

      if (!snapshot.exists) {
        return {
          'avgSystolic': null,
          'avgDiastolic': null,
          'avgHeartRate': null,
          'latestWeight': null,
          'recordCount': 0,
        };
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final records = <HealthRecordModel>[];
      
      data.forEach((key, value) {
        final recordData = Map<String, dynamic>.from(value as Map);
        records.add(HealthRecordModel.fromJson(recordData));
      });

      // Calculate averages
      int systolicSum = 0, systolicCount = 0;
      int diastolicSum = 0, diastolicCount = 0;
      int heartRateSum = 0, heartRateCount = 0;
      double? latestWeight;

      for (var record in records) {
        if (record.systolicBP != null) {
          systolicSum += record.systolicBP!;
          systolicCount++;
        }
        if (record.diastolicBP != null) {
          diastolicSum += record.diastolicBP!;
          diastolicCount++;
        }
        if (record.heartRate != null) {
          heartRateSum += record.heartRate!;
          heartRateCount++;
        }
        if (record.weight != null) {
          latestWeight = record.weight;
        }
      }

      return {
        'avgSystolic': systolicCount > 0 ? (systolicSum / systolicCount).round() : null,
        'avgDiastolic': diastolicCount > 0 ? (diastolicSum / diastolicCount).round() : null,
        'avgHeartRate': heartRateCount > 0 ? (heartRateSum / heartRateCount).round() : null,
        'latestWeight': latestWeight,
        'recordCount': records.length,
      };
    } catch (e) {
      print('Error getting health stats: $e');
      return {
        'avgSystolic': null,
        'avgDiastolic': null,
        'avgHeartRate': null,
        'latestWeight': null,
        'recordCount': 0,
      };
    }
  }
}
