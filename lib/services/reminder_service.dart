import 'package:firebase_database/firebase_database.dart';

/// Reminder Model - extracted from prescription_models
class ReminderModel {
  final String reminderId;
  final String userId;
  final String medicationName;
  final String dosage;
  final List<String> times;
  final bool isActive;
  final List<ReminderLog> logs;
  
  ReminderModel({
    required this.reminderId,
    required this.userId,
    required this.medicationName,
    required this.dosage,
    required this.times,
    this.isActive = true,
    this.logs = const [],
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final logsList = <ReminderLog>[];
    if (json['logs'] != null) {
      final logsData = json['logs'];
      if (logsData is Map) {
        logsData.forEach((key, value) {
          if (value is Map) {
            logsList.add(ReminderLog.fromJson(Map<String, dynamic>.from(value)));
          }
        });
      }
    }
    
    return ReminderModel(
      reminderId: json['reminderId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      times: (json['times'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
      logs: logsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'userId': userId,
      'medicationName': medicationName,
      'dosage': dosage,
      'times': times,
      'isActive': isActive,
    };
  }

  double get adherenceRate {
    if (logs.isEmpty) return 0.0;
    final takenCount = logs.where((l) => l.status == 'taken').length;
    return (takenCount / logs.length) * 100;
  }
}

class ReminderLog {
  final String logId;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final String status; // 'taken', 'missed', 'skipped'

  ReminderLog({
    required this.logId,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
  });

  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    return ReminderLog(
      logId: json['logId'] ?? '',
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(json['scheduledTime'] ?? 0),
      actualTime: json['actualTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['actualTime']) 
          : null,
      status: json['status'] ?? 'missed',
    );
  }
}

/// Reminder Service for medication reminders
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final _db = FirebaseDatabase.instance.ref();

  /// Get user reminders as stream
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _db
        .child('reminders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<ReminderModel> reminders = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              reminders.add(ReminderModel.fromJson(Map<String, dynamic>.from(value)));
            }
          });
        }
      }
      return reminders;
    });
  }

  /// Create a new reminder
  Future<String?> createReminder({
    required String userId,
    required String medicationName,
    required String dosage,
    required List<String> times,
    String? prescriptionId,
  }) async {
    try {
      final ref = _db.child('reminders').push();
      final reminderId = ref.key!;
      
      await ref.set({
        'reminderId': reminderId,
        'userId': userId,
        'medicationName': medicationName,
        'dosage': dosage,
        'times': times,
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      return reminderId;
    } catch (e) {
      print('Error creating reminder: $e');
      return null;
    }
  }

  /// Update reminder
  Future<bool> updateReminder({
    required String reminderId,
    required String medicationName,
    required String dosage,
    required List<String> times,
  }) async {
    try {
      await _db.child('reminders/$reminderId').update({
        'medicationName': medicationName,
        'dosage': dosage,
        'times': times,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error updating reminder: $e');
      return false;
    }
  }

  /// Toggle reminder active status
  Future<void> toggleReminder(String reminderId, bool isActive) async {
    await _db.child('reminders/$reminderId').update({'isActive': isActive});
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    await _db.child('reminders/$reminderId').remove();
  }

  /// Mark medication as taken
  Future<bool> markAsTaken(String reminderId, DateTime scheduledTime) async {
    try {
      final logRef = _db.child('reminders/$reminderId/logs').push();
      await logRef.set({
        'logId': logRef.key,
        'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        'actualTime': DateTime.now().millisecondsSinceEpoch,
        'status': 'taken',
      });
      return true;
    } catch (e) {
      print('Error marking as taken: $e');
      return false;
    }
  }

  /// Cancel follow-up reminder
  Future<void> cancelFollowUpReminder(String reminderId, DateTime scheduledTime) async {
    // Implementation for canceling follow-up - placeholder
  }

  /// Get adherence rate for a period
  Future<double> getAdherenceRate(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _db
          .child('reminders')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists || snapshot.value == null) return 0.0;

      int totalLogs = 0;
      int takenLogs = 0;

      final data = snapshot.value as Map;
      for (var entry in data.entries) {
        final reminderData = Map<String, dynamic>.from(entry.value as Map);
        final logs = reminderData['logs'];
        if (logs != null && logs is Map) {
          for (var logEntry in logs.entries) {
            final log = Map<String, dynamic>.from(logEntry.value as Map);
            final scheduledTime = DateTime.fromMillisecondsSinceEpoch(log['scheduledTime'] ?? 0);
            if (scheduledTime.isAfter(startDate) && scheduledTime.isBefore(endDate)) {
              totalLogs++;
              if (log['status'] == 'taken') takenLogs++;
            }
          }
        }
      }

      return totalLogs > 0 ? (takenLogs / totalLogs) * 100 : 0.0;
    } catch (e) {
      print('Error getting adherence rate: $e');
      return 0.0;
    }
  }
}
