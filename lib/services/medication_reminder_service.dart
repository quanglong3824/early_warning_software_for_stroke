import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:early_warning_software_for_stroke/services/health_chart_service.dart';
import 'package:early_warning_software_for_stroke/services/notification_service.dart';

/// Log entry for medication tracking
/// Implements Requirements 7.3 - logging medication taken events with timestamp
class MedicationLog {
  final int scheduledTime;
  final int? takenTime;
  final bool wasTaken;
  final String? notes;

  MedicationLog({
    required this.scheduledTime,
    this.takenTime,
    required this.wasTaken,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'scheduledTime': scheduledTime,
    'takenTime': takenTime,
    'wasTaken': wasTaken,
    'notes': notes,
  };

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
    scheduledTime: json['scheduledTime'] ?? 0,
    takenTime: json['takenTime'],
    wasTaken: json['wasTaken'] ?? false,
    notes: json['notes'],
  );
  
  /// Check if this log is within a date range
  bool isWithinRange(DateRange range) {
    final logDate = DateTime.fromMillisecondsSinceEpoch(scheduledTime);
    return range.contains(logDate);
  }
}

/// Medication reminder model
/// Implements Requirements 7.2 - reminder with times and logs for tracking
class MedicationReminder {
  final String reminderId;
  final String userId;
  final String prescriptionId;
  final String medicationName;
  final String dosage;
  final List<TimeOfDay> reminderTimes;
  final int startDate;
  final int? endDate;
  final bool isActive;
  final List<MedicationLog> logs;
  final int createdAt;
  final int? updatedAt;

  MedicationReminder({
    required this.reminderId,
    required this.userId,
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.logs = const [],
    int? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'reminderId': reminderId,
    'userId': userId,
    'prescriptionId': prescriptionId,
    'medicationName': medicationName,
    'dosage': dosage,
    'reminderTimes': reminderTimes.map((t) => {
      'hour': t.hour,
      'minute': t.minute,
    }).toList(),
    'startDate': startDate,
    'endDate': endDate,
    'isActive': isActive,
    'logs': logs.map((l) => l.toJson()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    final timesData = json['reminderTimes'] as List? ?? [];
    final logsData = json['logs'] as List? ?? [];
    
    return MedicationReminder(
      reminderId: json['reminderId'] ?? '',
      userId: json['userId'] ?? '',
      prescriptionId: json['prescriptionId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      reminderTimes: timesData.map((t) {
        final timeMap = Map<String, dynamic>.from(t);
        return TimeOfDay(
          hour: timeMap['hour'] ?? 0,
          minute: timeMap['minute'] ?? 0,
        );
      }).toList(),
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'],
      isActive: json['isActive'] ?? true,
      logs: logsData.map((l) => 
          MedicationLog.fromJson(Map<String, dynamic>.from(l))).toList(),
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'],
    );
  }
  
  /// Create a copy with updated fields
  MedicationReminder copyWith({
    String? reminderId,
    String? userId,
    String? prescriptionId,
    String? medicationName,
    String? dosage,
    List<TimeOfDay>? reminderTimes,
    int? startDate,
    int? endDate,
    bool? isActive,
    List<MedicationLog>? logs,
    int? createdAt,
    int? updatedAt,
  }) {
    return MedicationReminder(
      reminderId: reminderId ?? this.reminderId,
      userId: userId ?? this.userId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      logs: logs ?? this.logs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Get logs within a date range
  List<MedicationLog> getLogsInRange(DateRange range) {
    return logs.where((log) => log.isWithinRange(range)).toList();
  }
  
  /// Calculate adherence rate for this reminder within a date range
  double calculateAdherenceInRange(DateRange range) {
    final logsInRange = getLogsInRange(range);
    if (logsInRange.isEmpty) return 0.0;
    
    final takenCount = logsInRange.where((log) => log.wasTaken).length;
    return (takenCount / logsInRange.length) * 100;
  }
}

/// Abstract interface for Medication Reminder Service
/// Implements Requirements 7.2, 7.3, 7.4, 7.5
abstract class IMedicationReminderService {
  /// Creates a new medication reminder
  Future<String> createReminder(MedicationReminder reminder);
  
  /// Updates an existing reminder
  Future<void> updateReminder(String reminderId, MedicationReminder reminder);
  
  /// Deletes a reminder
  Future<void> deleteReminder(String reminderId);
  
  /// Marks medication as taken
  Future<void> markAsTaken(String reminderId, DateTime takenAt);
  
  /// Calculates adherence rate for a date range
  Future<double> getAdherenceRate(String userId, DateRange range);
  
  /// Gets active reminders stream for a user
  Stream<List<MedicationReminder>> getActiveReminders(String userId);
  
  /// Schedules follow-up reminder for missed dose
  Future<void> scheduleFollowUpReminder(String reminderId, DateTime originalTime);
}


/// Implementation of Medication Reminder Service
/// Implements Requirements 7.2, 7.3, 7.4, 7.5
class MedicationReminderService implements IMedicationReminderService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final NotificationService _notificationService = NotificationService();
  static const int _followUpDelayMinutes = 30;
  
  @override
  Future<String> createReminder(MedicationReminder reminder) async {
    final ref = _database.child('medication_reminders').push();
    final reminderId = ref.key!;
    
    final reminderWithId = MedicationReminder(
      reminderId: reminderId,
      userId: reminder.userId,
      prescriptionId: reminder.prescriptionId,
      medicationName: reminder.medicationName,
      dosage: reminder.dosage,
      reminderTimes: reminder.reminderTimes,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      isActive: reminder.isActive,
      logs: reminder.logs,
    );
    
    await ref.set(reminderWithId.toJson());
    
    // Schedule notifications for each reminder time
    await _scheduleReminderNotifications(reminderWithId);
    
    return reminderId;
  }
  
  @override
  Future<void> updateReminder(String reminderId, MedicationReminder reminder) async {
    final updatedReminder = reminder.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _database.child('medication_reminders/$reminderId').update(updatedReminder.toJson());
    
    // Reschedule notifications
    await _cancelReminderNotifications(reminderId);
    if (updatedReminder.isActive) {
      await _scheduleReminderNotifications(updatedReminder);
    }
  }
  
  @override
  Future<void> deleteReminder(String reminderId) async {
    await _cancelReminderNotifications(reminderId);
    await _database.child('medication_reminders/$reminderId').remove();
  }
  
  /// Mark medication as taken with timestamp logging
  /// Implements Requirements 7.3 - log event with timestamp
  @override
  Future<void> markAsTaken(String reminderId, DateTime takenAt) async {
    final snapshot = await _database.child('medication_reminders/$reminderId').get();
    
    if (!snapshot.exists) return;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final logs = (data['logs'] as List? ?? [])
        .map((l) => MedicationLog.fromJson(Map<String, dynamic>.from(l)))
        .toList();
    
    // Add new log entry with timestamp
    logs.add(MedicationLog(
      scheduledTime: takenAt.millisecondsSinceEpoch,
      takenTime: DateTime.now().millisecondsSinceEpoch,
      wasTaken: true,
    ));
    
    await _database.child('medication_reminders/$reminderId').update({
      'logs': logs.map((l) => l.toJson()).toList(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Cancel any pending follow-up reminders for this dose
    await _cancelFollowUpReminder(reminderId, takenAt);
  }
  
  /// Mark medication as missed (not taken)
  Future<void> markAsMissed(String reminderId, DateTime scheduledTime) async {
    final snapshot = await _database.child('medication_reminders/$reminderId').get();
    
    if (!snapshot.exists) return;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final logs = (data['logs'] as List? ?? [])
        .map((l) => MedicationLog.fromJson(Map<String, dynamic>.from(l)))
        .toList();
    
    // Add log entry for missed dose
    logs.add(MedicationLog(
      scheduledTime: scheduledTime.millisecondsSinceEpoch,
      takenTime: null,
      wasTaken: false,
    ));
    
    await _database.child('medication_reminders/$reminderId').update({
      'logs': logs.map((l) => l.toJson()).toList(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Calculate adherence rate for a user within a date range
  /// Implements Requirements 7.5 - display adherence percentage
  @override
  Future<double> getAdherenceRate(String userId, DateRange range) async {
    final snapshot = await _database
        .child('medication_reminders')
        .orderByChild('userId')
        .equalTo(userId)
        .get();
    
    if (!snapshot.exists) return 0.0;
    
    int totalScheduled = 0;
    int totalTaken = 0;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      final reminder = MedicationReminder.fromJson(
          Map<String, dynamic>.from(value as Map));
      
      for (final log in reminder.logs) {
        final logDate = DateTime.fromMillisecondsSinceEpoch(log.scheduledTime);
        
        if (range.contains(logDate)) {
          totalScheduled++;
          if (log.wasTaken) {
            totalTaken++;
          }
        }
      }
    });
    
    return calculateAdherence(totalTaken, totalScheduled);
  }
  
  @override
  Stream<List<MedicationReminder>> getActiveReminders(String userId) {
    return _database
        .child('medication_reminders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <MedicationReminder>[];
          
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return data.entries
              .map((e) => MedicationReminder.fromJson(
                  Map<String, dynamic>.from(e.value as Map)))
              .where((r) => r.isActive)
              .toList();
        });
  }
  
  /// Get all reminders for a user (including inactive)
  Stream<List<MedicationReminder>> getAllReminders(String userId) {
    return _database
        .child('medication_reminders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <MedicationReminder>[];
          
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return data.entries
              .map((e) => MedicationReminder.fromJson(
                  Map<String, dynamic>.from(e.value as Map)))
              .toList();
        });
  }
  
  /// Get a single reminder by ID
  Future<MedicationReminder?> getReminder(String reminderId) async {
    final snapshot = await _database.child('medication_reminders/$reminderId').get();
    
    if (!snapshot.exists) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return MedicationReminder.fromJson(data);
  }
  
  /// Schedule follow-up reminder for missed dose
  /// Implements Requirements 7.4 - send follow-up after 30 minutes if miss dose
  @override
  Future<void> scheduleFollowUpReminder(String reminderId, DateTime originalTime) async {
    final followUpTime = originalTime.add(
        const Duration(minutes: _followUpDelayMinutes));
    
    // Get reminder details for notification
    final reminder = await getReminder(reminderId);
    if (reminder == null) return;
    
    // Store follow-up reminder in database
    final followUpRef = _database.child('follow_up_reminders').push();
    final followUpId = followUpRef.key!;
    
    await followUpRef.set({
      'followUpId': followUpId,
      'originalReminderId': reminderId,
      'originalTime': originalTime.millisecondsSinceEpoch,
      'followUpTime': followUpTime.millisecondsSinceEpoch,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Schedule local notification for follow-up
    await _notificationService.scheduleFollowUpReminder(
      id: followUpId.hashCode,
      medicationName: reminder.medicationName,
      dosage: reminder.dosage,
      delayMinutes: _followUpDelayMinutes,
      prescriptionId: reminder.prescriptionId,
    );
  }
  
  /// Check for missed doses and schedule follow-up reminders
  Future<void> checkAndScheduleFollowUps(String userId) async {
    final reminders = await getActiveReminders(userId).first;
    final now = DateTime.now();
    
    for (final reminder in reminders) {
      for (final time in reminder.reminderTimes) {
        final scheduledTime = DateTime(
          now.year, now.month, now.day,
          time.hour, time.minute,
        );
        
        // Check if this time has passed and no log exists for today
        if (scheduledTime.isBefore(now)) {
          final hasLogForToday = reminder.logs.any((log) {
            final logDate = DateTime.fromMillisecondsSinceEpoch(log.scheduledTime);
            return logDate.year == now.year &&
                   logDate.month == now.month &&
                   logDate.day == now.day &&
                   logDate.hour == time.hour &&
                   logDate.minute == time.minute;
          });
          
          if (!hasLogForToday) {
            // Check if follow-up already scheduled
            final hasFollowUp = await _hasFollowUpScheduled(
              reminder.reminderId, 
              scheduledTime,
            );
            
            if (!hasFollowUp) {
              await scheduleFollowUpReminder(reminder.reminderId, scheduledTime);
            }
          }
        }
      }
    }
  }
  
  /// Cancel follow-up reminder when medication is taken
  Future<void> _cancelFollowUpReminder(String reminderId, DateTime scheduledTime) async {
    final snapshot = await _database
        .child('follow_up_reminders')
        .orderByChild('originalReminderId')
        .equalTo(reminderId)
        .get();
    
    if (!snapshot.exists) return;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final followUp = Map<String, dynamic>.from(entry.value as Map);
      final originalTime = followUp['originalTime'] as int;
      
      // Check if this follow-up is for the same scheduled time (same day)
      final followUpDate = DateTime.fromMillisecondsSinceEpoch(originalTime);
      if (followUpDate.year == scheduledTime.year &&
          followUpDate.month == scheduledTime.month &&
          followUpDate.day == scheduledTime.day) {
        // Cancel the notification
        final followUpId = followUp['followUpId'] as String;
        await _notificationService.cancelNotification(followUpId.hashCode);
        
        // Update status to cancelled
        await _database.child('follow_up_reminders/${entry.key}').update({
          'status': 'cancelled',
          'cancelledAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }
  
  /// Check if a follow-up reminder is already scheduled
  Future<bool> _hasFollowUpScheduled(String reminderId, DateTime scheduledTime) async {
    final snapshot = await _database
        .child('follow_up_reminders')
        .orderByChild('originalReminderId')
        .equalTo(reminderId)
        .get();
    
    if (!snapshot.exists) return false;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final followUp = Map<String, dynamic>.from(entry.value as Map);
      final originalTime = followUp['originalTime'] as int;
      final status = followUp['status'] as String;
      
      if (status == 'pending') {
        final followUpDate = DateTime.fromMillisecondsSinceEpoch(originalTime);
        if (followUpDate.year == scheduledTime.year &&
            followUpDate.month == scheduledTime.month &&
            followUpDate.day == scheduledTime.day) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Schedule notifications for all reminder times
  Future<void> _scheduleReminderNotifications(MedicationReminder reminder) async {
    for (int i = 0; i < reminder.reminderTimes.length; i++) {
      final time = reminder.reminderTimes[i];
      final notificationId = '${reminder.reminderId}_$i'.hashCode;
      
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: 'Nhắc nhở uống thuốc',
        body: '${reminder.medicationName} - ${reminder.dosage}',
        hour: time.hour,
        minute: time.minute,
        payload: {
          'type': 'reminder',
          'reminderId': reminder.reminderId,
          'medicationName': reminder.medicationName,
          'dosage': reminder.dosage,
        },
      );
    }
  }
  
  /// Cancel all notifications for a reminder
  Future<void> _cancelReminderNotifications(String reminderId) async {
    final reminder = await getReminder(reminderId);
    if (reminder == null) return;
    
    for (int i = 0; i < reminder.reminderTimes.length; i++) {
      final notificationId = '${reminderId}_$i'.hashCode;
      await _notificationService.cancelNotification(notificationId);
    }
  }
  
  /// Calculate adherence from logs (pure function for testing)
  /// Property 11: Medication Adherence Calculation
  /// Validates: Requirements 7.5
  static double calculateAdherence(int takenDoses, int scheduledDoses) {
    if (scheduledDoses == 0) return 0.0;
    return (takenDoses / scheduledDoses) * 100;
  }
  
  /// Calculate follow-up time (pure function for testing)
  /// Property 12: Follow-up Reminder Scheduling
  /// Validates: Requirements 7.4
  static DateTime calculateFollowUpTime(DateTime originalTime) {
    return originalTime.add(const Duration(minutes: _followUpDelayMinutes));
  }
}
