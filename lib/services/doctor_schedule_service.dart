import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:early_warning_software_for_stroke/services/health_chart_service.dart';

/// Time slot for appointments
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isBooked;
  final String? patientId;
  final String? appointmentId;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.patientId,
    this.appointmentId,
  });

  Map<String, dynamic> toJson() => {
    'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
    'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
    'isBooked': isBooked,
    'patientId': patientId,
    'appointmentId': appointmentId,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final startMap = Map<String, dynamic>.from(json['startTime'] ?? {});
    final endMap = Map<String, dynamic>.from(json['endTime'] ?? {});
    
    return TimeSlot(
      startTime: TimeOfDay(
        hour: startMap['hour'] ?? 0,
        minute: startMap['minute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: endMap['hour'] ?? 0,
        minute: endMap['minute'] ?? 0,
      ),
      isBooked: json['isBooked'] ?? false,
      patientId: json['patientId'],
      appointmentId: json['appointmentId'],
    );
  }
}

/// Day schedule with working hours and slots
class DaySchedule {
  final bool isWorking;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int slotDurationMinutes;
  final List<TimeSlot> bookedSlots;

  DaySchedule({
    this.isWorking = false,
    this.startTime,
    this.endTime,
    this.slotDurationMinutes = 30,
    this.bookedSlots = const [],
  });


  Map<String, dynamic> toJson() => {
    'isWorking': isWorking,
    'startTime': startTime != null 
        ? {'hour': startTime!.hour, 'minute': startTime!.minute} 
        : null,
    'endTime': endTime != null 
        ? {'hour': endTime!.hour, 'minute': endTime!.minute} 
        : null,
    'slotDurationMinutes': slotDurationMinutes,
    'bookedSlots': bookedSlots.map((s) => s.toJson()).toList(),
  };

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final startMap = json['startTime'] as Map?;
    final endMap = json['endTime'] as Map?;
    final slotsData = json['bookedSlots'] as List? ?? [];
    
    return DaySchedule(
      isWorking: json['isWorking'] ?? false,
      startTime: startMap != null 
          ? TimeOfDay(hour: startMap['hour'] ?? 0, minute: startMap['minute'] ?? 0)
          : null,
      endTime: endMap != null 
          ? TimeOfDay(hour: endMap['hour'] ?? 0, minute: endMap['minute'] ?? 0)
          : null,
      slotDurationMinutes: json['slotDurationMinutes'] ?? 30,
      bookedSlots: slotsData.map((s) => 
          TimeSlot.fromJson(Map<String, dynamic>.from(s))).toList(),
    );
  }
}

/// Weekly schedule for a doctor
class WeeklySchedule {
  final Map<int, DaySchedule> daySlots; // 1-7 for Mon-Sun

  WeeklySchedule({required this.daySlots});

  Map<String, dynamic> toJson() => {
    'daySlots': daySlots.map((key, value) => 
        MapEntry(key.toString(), value.toJson())),
  };

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final slotsData = Map<String, dynamic>.from(json['daySlots'] ?? {});
    
    return WeeklySchedule(
      daySlots: slotsData.map((key, value) => MapEntry(
        int.parse(key),
        DaySchedule.fromJson(Map<String, dynamic>.from(value)),
      )),
    );
  }
}

/// Leave record for a doctor
class LeaveRecord {
  final String leaveId;
  final String doctorId;
  final int startDate;
  final int endDate;
  final String? reason;

  LeaveRecord({
    required this.leaveId,
    required this.doctorId,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'leaveId': leaveId,
    'doctorId': doctorId,
    'startDate': startDate,
    'endDate': endDate,
    'reason': reason,
  };

  factory LeaveRecord.fromJson(Map<String, dynamic> json) => LeaveRecord(
    leaveId: json['leaveId'] ?? '',
    doctorId: json['doctorId'] ?? '',
    startDate: json['startDate'] ?? 0,
    endDate: json['endDate'] ?? 0,
    reason: json['reason'],
  );
}


/// Doctor availability model
class DoctorAvailability {
  final String doctorId;
  final WeeklySchedule weeklySchedule;
  final List<LeaveRecord> leaves;

  DoctorAvailability({
    required this.doctorId,
    required this.weeklySchedule,
    this.leaves = const [],
  });

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'weeklySchedule': weeklySchedule.toJson(),
    'leaves': leaves.map((l) => l.toJson()).toList(),
  };

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) {
    final leavesData = json['leaves'] as List? ?? [];
    
    return DoctorAvailability(
      doctorId: json['doctorId'] ?? '',
      weeklySchedule: WeeklySchedule.fromJson(
          Map<String, dynamic>.from(json['weeklySchedule'] ?? {'daySlots': {}})),
      leaves: leavesData.map((l) => 
          LeaveRecord.fromJson(Map<String, dynamic>.from(l))).toList(),
    );
  }
}

/// Abstract interface for Doctor Schedule Service
/// Implements Requirements 8.1, 8.2, 8.3, 8.4
abstract class IDoctorScheduleService {
  /// Sets weekly schedule for a doctor
  Future<void> setWeeklySchedule(String doctorId, WeeklySchedule schedule);
  
  /// Sets leave period for a doctor
  Future<void> setLeave(String doctorId, DateRange leaveRange, {String? reason});
  
  /// Gets available time slots for a specific date
  Future<List<TimeSlot>> getAvailableSlots(String doctorId, DateTime date);
  
  /// Books a time slot for a patient
  Future<void> bookSlot(String doctorId, DateTime slotTime, String patientId);
  
  /// Checks if a date is within a leave period
  bool isOnLeave(DateTime date, List<LeaveRecord> leaves);
  
  /// Generates time slots from day schedule
  List<TimeSlot> generateTimeSlots(DaySchedule daySchedule);
}


/// Implementation of Doctor Schedule Service
class DoctorScheduleService implements IDoctorScheduleService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  /// Notifies affected patients when doctor availability changes
  /// Implements Requirement 8.5
  Future<void> notifyAffectedPatients(String doctorId, String changeType, {DateTime? affectedDate}) async {
    try {
      // Get all pending/confirmed appointments for this doctor
      final appointmentsSnapshot = await _database
          .child('appointments')
          .orderByChild('doctorId')
          .equalTo(doctorId)
          .get();
      
      if (!appointmentsSnapshot.exists) return;
      
      final appointments = Map<String, dynamic>.from(appointmentsSnapshot.value as Map);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Get doctor name
      final doctorSnapshot = await _database.child('users/$doctorId').get();
      String doctorName = 'Bác sĩ';
      if (doctorSnapshot.exists) {
        final doctorData = Map<String, dynamic>.from(doctorSnapshot.value as Map);
        doctorName = doctorData['name'] ?? 'Bác sĩ';
      }
      
      for (final entry in appointments.entries) {
        final appointment = Map<String, dynamic>.from(entry.value as Map);
        final status = appointment['status'] as String?;
        final appointmentTime = appointment['appointmentTime'] as int?;
        final patientId = appointment['userId'] as String?;
        
        // Only notify for future pending/confirmed appointments
        if (patientId == null || appointmentTime == null) continue;
        if (status != 'pending' && status != 'confirmed') continue;
        if (appointmentTime < now) continue;
        
        // If affectedDate is specified, only notify for appointments on that date
        if (affectedDate != null) {
          final appointmentDate = DateTime.fromMillisecondsSinceEpoch(appointmentTime);
          if (!DateUtils.isSameDay(appointmentDate, affectedDate)) continue;
        }
        
        // Create notification for the patient
        await _database.child('notifications/$patientId').push().set({
          'type': 'schedule_change',
          'title': 'Thay đổi lịch khám',
          'message': changeType == 'leave'
              ? 'Bác sĩ $doctorName đã đặt ngày nghỉ. Lịch hẹn của bạn có thể bị ảnh hưởng.'
              : 'Bác sĩ $doctorName đã thay đổi lịch làm việc. Vui lòng kiểm tra lại lịch hẹn.',
          'data': {
            'doctorId': doctorId,
            'appointmentId': entry.key,
            'route': '/appointments',
          },
          'isRead': false,
          'createdAt': now,
        });
      }
    } catch (e) {
      debugPrint('Error notifying affected patients: $e');
    }
  }
  
  /// Gets the full doctor availability including schedule and leaves
  Future<DoctorAvailability?> getDoctorAvailability(String doctorId) async {
    final snapshot = await _database.child('doctor_schedules/$doctorId').get();
    
    if (!snapshot.exists) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return DoctorAvailability.fromJson({
      'doctorId': doctorId,
      ...data,
    });
  }
  
  /// Gets all leaves for a doctor
  Future<List<LeaveRecord>> getLeaves(String doctorId) async {
    final snapshot = await _database.child('doctor_schedules/$doctorId/leaves').get();
    
    if (!snapshot.exists) return [];
    
    final data = snapshot.value;
    final List<LeaveRecord> leaves = [];
    
    if (data is Map) {
      data.forEach((key, value) {
        if (value != null) {
          leaves.add(LeaveRecord.fromJson(Map<String, dynamic>.from(value as Map)));
        }
      });
    }
    
    return leaves;
  }
  
  /// Removes a leave record
  Future<void> removeLeave(String doctorId, String leaveId) async {
    await _database.child('doctor_schedules/$doctorId/leaves/$leaveId').remove();
  }
  
  @override
  Future<void> setWeeklySchedule(String doctorId, WeeklySchedule schedule) async {
    await _database.child('doctor_schedules/$doctorId/weeklySchedule')
        .set(schedule.toJson());
    
    // Notify affected patients about schedule change (Requirement 8.5)
    await notifyAffectedPatients(doctorId, 'schedule');
  }
  
  @override
  Future<void> setLeave(String doctorId, DateRange leaveRange, {String? reason}) async {
    final leaveRef = _database.child('doctor_schedules/$doctorId/leaves').push();
    
    final leave = LeaveRecord(
      leaveId: leaveRef.key!,
      doctorId: doctorId,
      startDate: leaveRange.start.millisecondsSinceEpoch,
      endDate: leaveRange.end.millisecondsSinceEpoch,
      reason: reason,
    );
    
    await leaveRef.set(leave.toJson());
    
    // Notify affected patients about leave (Requirement 8.5)
    // Notify for each day in the leave range
    var currentDate = leaveRange.start;
    while (!currentDate.isAfter(leaveRange.end)) {
      await notifyAffectedPatients(doctorId, 'leave', affectedDate: currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
  
  @override
  Future<List<TimeSlot>> getAvailableSlots(String doctorId, DateTime date) async {
    final snapshot = await _database.child('doctor_schedules/$doctorId').get();
    
    DoctorAvailability availability;
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      availability = DoctorAvailability.fromJson({
        'doctorId': doctorId,
        ...data,
      });
    } else {
      // Create empty availability to trigger fallback logic later
      availability = DoctorAvailability(
        doctorId: doctorId,
        weeklySchedule: WeeklySchedule(daySlots: {}),
      );
    }
    
    // Check if on leave
    if (isOnLeave(date, availability.leaves)) {
      return [];
    }
    
    // Get day of week (1 = Monday, 7 = Sunday)
    final dayOfWeek = date.weekday;
    final daySchedule = availability.weeklySchedule.daySlots[dayOfWeek];
    
    // Generate all possible slots
    List<TimeSlot> allSlots;
    Set<String> bookedTimes = {};
    
    // If no specific schedule for this day, use default working hours (8:00 - 17:00)
    // providing a fallback for demo purposes
    if (daySchedule == null || !daySchedule.isWorking) {
      if (availability.weeklySchedule.daySlots.isEmpty) {
        // Only use fallback if NO schedule exists at all (demo mode)
        final defaultSchedule = DaySchedule(
          isWorking: true,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotDurationMinutes: 30,
        );
        allSlots = generateTimeSlots(defaultSchedule);
        
        // Also check for any appointments actually booked in the 'appointments' node
        // ignoring the doctor_schedule structure if it's broken
        try {
          // Ideally we would query 'appointments' by doctorId and date here
          // For now, we assume if schedule is missing, we are in a simple test state
        } catch (_) {}
        
      } else {
        return []; // Schedule exists but this day is explicitly not working
      }
    } else {
      allSlots = generateTimeSlots(daySchedule);
      bookedTimes = daySchedule.bookedSlots
        .map((s) => '${s.startTime.hour}:${s.startTime.minute}')
        .toSet();
    }
    
    // Filter out booked slots
    
    return allSlots.where((slot) {
      final slotKey = '${slot.startTime.hour}:${slot.startTime.minute}';
      return !bookedTimes.contains(slotKey);
    }).toList();
  }


  @override
  Future<void> bookSlot(String doctorId, DateTime slotTime, String patientId) async {
    final dayOfWeek = slotTime.weekday;
    final slotTimeOfDay = TimeOfDay(hour: slotTime.hour, minute: slotTime.minute);
    
    // Create appointment
    final appointmentRef = _database.child('appointments').push();
    final appointmentId = appointmentRef.key!;
    
    await appointmentRef.set({
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'scheduledTime': slotTime.millisecondsSinceEpoch,
      'status': 'confirmed',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Mark slot as booked
    final snapshot = await _database
        .child('doctor_schedules/$doctorId/weeklySchedule/daySlots/$dayOfWeek/bookedSlots')
        .get();
    
    List<Map<String, dynamic>> bookedSlots = [];
    if (snapshot.exists) {
      final data = snapshot.value as List?;
      if (data != null) {
        bookedSlots = data.map((s) => Map<String, dynamic>.from(s as Map)).toList();
      }
    }
    
    bookedSlots.add(TimeSlot(
      startTime: slotTimeOfDay,
      endTime: TimeOfDay(
        hour: slotTimeOfDay.hour,
        minute: slotTimeOfDay.minute + 30,
      ),
      isBooked: true,
      patientId: patientId,
      appointmentId: appointmentId,
    ).toJson());
    
    await _database
        .child('doctor_schedules/$doctorId/weeklySchedule/daySlots/$dayOfWeek/bookedSlots')
        .set(bookedSlots);
  }
  
  @override
  bool isOnLeave(DateTime date, List<LeaveRecord> leaves) {
    for (final leave in leaves) {
      final startDate = DateTime.fromMillisecondsSinceEpoch(leave.startDate);
      final endDate = DateTime.fromMillisecondsSinceEpoch(leave.endDate);
      
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }
  
  @override
  List<TimeSlot> generateTimeSlots(DaySchedule daySchedule) {
    if (!daySchedule.isWorking || 
        daySchedule.startTime == null || 
        daySchedule.endTime == null) {
      return [];
    }
    
    final slots = <TimeSlot>[];
    var currentMinutes = daySchedule.startTime!.hour * 60 + 
        daySchedule.startTime!.minute;
    final endMinutes = daySchedule.endTime!.hour * 60 + 
        daySchedule.endTime!.minute;
    
    while (currentMinutes + daySchedule.slotDurationMinutes <= endMinutes) {
      final startHour = currentMinutes ~/ 60;
      final startMinute = currentMinutes % 60;
      final endHour = (currentMinutes + daySchedule.slotDurationMinutes) ~/ 60;
      final endMinute = (currentMinutes + daySchedule.slotDurationMinutes) % 60;
      
      slots.add(TimeSlot(
        startTime: TimeOfDay(hour: startHour, minute: startMinute),
        endTime: TimeOfDay(hour: endHour, minute: endMinute),
      ));
      
      currentMinutes += daySchedule.slotDurationMinutes;
    }
    
    return slots;
  }
}
