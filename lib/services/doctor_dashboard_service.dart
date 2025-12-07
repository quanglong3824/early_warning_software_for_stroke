import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Model for dashboard statistics
class DashboardStats {
  final int todayAppointments;
  final int activeSOSCases;
  final int unreadMessages;
  final int todayPrescriptions;
  final int totalPatients;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.todayAppointments,
    required this.activeSOSCases,
    required this.unreadMessages,
    required this.todayPrescriptions,
    required this.totalPatients,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayAppointments: json['todayAppointments'] as int? ?? 0,
      activeSOSCases: json['activeSOSCases'] as int? ?? 0,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
      todayPrescriptions: json['todayPrescriptions'] as int? ?? 0,
      totalPatients: json['totalPatients'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'todayAppointments': todayAppointments,
        'activeSOSCases': activeSOSCases,
        'unreadMessages': unreadMessages,
        'todayPrescriptions': todayPrescriptions,
        'totalPatients': totalPatients,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };

  DashboardStats copyWith({
    int? todayAppointments,
    int? activeSOSCases,
    int? unreadMessages,
    int? todayPrescriptions,
    int? totalPatients,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      todayAppointments: todayAppointments ?? this.todayAppointments,
      activeSOSCases: activeSOSCases ?? this.activeSOSCases,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      todayPrescriptions: todayPrescriptions ?? this.todayPrescriptions,
      totalPatients: totalPatients ?? this.totalPatients,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Model for patient summary in dashboard
class PatientSummary {
  final String id;
  final String name;
  final String? avatarUrl;
  final String status;
  final DateTime? lastVisit;

  const PatientSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.status,
    this.lastVisit,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Bệnh nhân',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'stable',
      lastVisit: json['lastVisit'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastVisit'] as int)
          : null,
    );
  }
}

/// Service quản lý dữ liệu dashboard cho bác sĩ
/// Implements Requirements: 1.1, 1.2, 1.3, 1.4, 1.6
class DoctorDashboardService {
  static final DoctorDashboardService _instance =
      DoctorDashboardService._internal();
  factory DoctorDashboardService() => _instance;
  DoctorDashboardService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Helper to get start and end of today in milliseconds
  Map<String, int> _getTodayRange() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return {
      'start': startOfDay.millisecondsSinceEpoch,
      'end': endOfDay.millisecondsSinceEpoch,
    };
  }

  /// Lấy số lượng lịch hẹn hôm nay
  /// Requirements: 1.1
  Stream<int> getTodayAppointmentCount(String doctorId) {
    final todayRange = _getTodayRange();

    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

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

      int count = 0;
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final appointmentData = Map<String, dynamic>.from(entry.value as Map);
        final appointmentTime = appointmentData['appointmentTime'] as int? ?? 0;

        if (appointmentTime >= todayRange['start']! &&
            appointmentTime < todayRange['end']!) {
          count++;
        }
      }
      return count;
    });
  }

  /// Lấy số lượng SOS đang hoạt động
  /// Requirements: 1.2
  Stream<int> getActiveSOSCount() {
    return _db.child('sos_requests').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

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

      int count = 0;
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final sosData = Map<String, dynamic>.from(entry.value as Map);
        final status = sosData['status'] as String? ?? '';

        // Count SOS cases that are not resolved or cancelled
        if (status != 'resolved' && status != 'cancelled') {
          count++;
        }
      }
      return count;
    });
  }

  /// Lấy số lượng tin nhắn chưa đọc
  /// Requirements: 1.3
  Stream<int> getUnreadMessageCount(String doctorId) {
    return _db
        .child('conversations')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

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

      int totalUnread = 0;
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final convData = Map<String, dynamic>.from(entry.value as Map);
        final unreadCount = convData['doctorUnreadCount'] as int? ?? 0;
        totalUnread += unreadCount;
      }
      return totalUnread;
    });
  }

  /// Lấy số lượng đơn thuốc hôm nay
  /// Requirements: 1.4
  Stream<int> getTodayPrescriptionCount(String doctorId) {
    final todayRange = _getTodayRange();

    return _db
        .child('prescriptions')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

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

      int count = 0;
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final prescriptionData = Map<String, dynamic>.from(entry.value as Map);
        final createdAt = prescriptionData['createdAt'] as int? ??
            prescriptionData['prescribedDate'] as int? ??
            0;

        if (createdAt >= todayRange['start']! &&
            createdAt < todayRange['end']!) {
          count++;
        }
      }
      return count;
    });
  }

  /// Lấy danh sách bệnh nhân gần đây
  /// Requirements: 1.6
  Stream<List<PatientSummary>> getRecentPatients(String doctorId,
      {int limit = 5}) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <PatientSummary>[];
      }

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

      // Get unique patient IDs with their most recent appointment time
      final Map<String, int> patientLastVisit = {};
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final appointmentData = Map<String, dynamic>.from(entry.value as Map);
        final userId = appointmentData['userId'] as String?;
        final appointmentTime = appointmentData['appointmentTime'] as int? ?? 0;

        if (userId != null) {
          if (!patientLastVisit.containsKey(userId) ||
              patientLastVisit[userId]! < appointmentTime) {
            patientLastVisit[userId] = appointmentTime;
          }
        }
      }

      // Sort by most recent visit and take top 'limit'
      final sortedPatients = patientLastVisit.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topPatients = sortedPatients.take(limit).toList();

      // Fetch patient details
      final List<PatientSummary> patients = [];
      for (var entry in topPatients) {
        try {
          final userSnapshot =
              await _db.child('users').child(entry.key).get();
          if (userSnapshot.exists && userSnapshot.value != null) {
            final userData =
                Map<String, dynamic>.from(userSnapshot.value as Map);
            patients.add(PatientSummary(
              id: entry.key,
              name: userData['name'] as String? ?? 'Bệnh nhân',
              avatarUrl: userData['avatarUrl'] as String?,
              status: userData['healthStatus'] as String? ?? 'stable',
              lastVisit: DateTime.fromMillisecondsSinceEpoch(entry.value),
            ));
          }
        } catch (e) {
          print('Error fetching patient ${entry.key}: $e');
        }
      }

      return patients;
    });
  }

  /// Lấy tổng số bệnh nhân của bác sĩ
  Stream<int> getTotalPatientCount(String doctorId) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

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

      // Count unique patient IDs
      final Set<String> uniquePatients = {};
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final appointmentData = Map<String, dynamic>.from(entry.value as Map);
        final userId = appointmentData['userId'] as String?;
        if (userId != null) {
          uniquePatients.add(userId);
        }
      }
      return uniquePatients.length;
    });
  }

  /// Lấy thống kê dashboard theo thời gian thực (combined stream)
  /// Requirements: 1.1, 1.2, 1.3, 1.4
  Stream<DashboardStats> getDashboardStats(String doctorId) {
    // Combine all streams into one
    return getTodayAppointmentCount(doctorId).asyncExpand((appointments) {
      return getActiveSOSCount().asyncExpand((sos) {
        return getUnreadMessageCount(doctorId).asyncExpand((messages) {
          return getTodayPrescriptionCount(doctorId).asyncExpand((prescriptions) {
            return getTotalPatientCount(doctorId).map((patients) {
              return DashboardStats(
                todayAppointments: appointments,
                activeSOSCases: sos,
                unreadMessages: messages,
                todayPrescriptions: prescriptions,
                totalPatients: patients,
                lastUpdated: DateTime.now(),
              );
            });
          });
        });
      });
    });
  }
}
