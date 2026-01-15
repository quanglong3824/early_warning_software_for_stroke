import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/appointment_model.dart';
import '../data/models/user_model.dart';
import '../data/models/health_record_model.dart';
import '../services/auth_service.dart';
import '../services/enhanced_notification_service.dart';

/// Model chi tiết lịch hẹn với thông tin bệnh nhân đầy đủ
class AppointmentDetailModel {
  final AppointmentModel appointment;
  final UserModel? patient;
  final List<AppointmentModel> previousAppointments;
  final List<HealthRecordModel> healthRecords;

  AppointmentDetailModel({
    required this.appointment,
    this.patient,
    this.previousAppointments = const [],
    this.healthRecords = const [],
  });
}

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();

  /// Get all appointments for a user
  Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _db
        .child('appointments')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .asyncMap((event) async {
      final List<AppointmentModel> appointments = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        // Handle if value is List (Firebase array behavior) or Map
        final dynamic value = event.snapshot.value;
        Map<dynamic, dynamic> data = {};
        
        if (value is Map) {
          data = value;
        } else if (value is List) {
           // Convert List to Map if needed, or iterate
           for (int i = 0; i < value.length; i++) {
             if (value[i] != null) {
               data[i.toString()] = value[i];
             }
           }
        }

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final appointmentData = Map<String, dynamic>.from(entry.value as Map);
          
          // Fetch doctor name if not already present
          if (appointmentData['doctorName'] == null) {
            final doctorId = appointmentData['doctorId'] as String?;
            if (doctorId != null) {
              try {
                final doctorSnapshot = await _db.child('users').child(doctorId).get();
                if (doctorSnapshot.exists) {
                  final doctorData = Map<String, dynamic>.from(doctorSnapshot.value as Map);
                  appointmentData['doctorName'] = doctorData['name'] as String? ?? 'Bác sĩ';
                }
              } catch (e) {
                print('Error fetching doctor name: $e');
                appointmentData['doctorName'] = 'Bác sĩ';
              }
            }
          }
          
          appointments.add(AppointmentModel.fromJson(appointmentData));
        }
      }
      // Sort by appointmentTime descending (newest first)
      appointments.sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));
      return appointments;
    });
  }

  /// Get upcoming appointments
  Stream<List<AppointmentModel>> getUpcomingAppointments(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return getUserAppointments(userId).map((appointments) {
      return appointments.where((apt) => apt.appointmentTime > now).toList();
    });
  }

  /// Get past appointments
  Stream<List<AppointmentModel>> getPastAppointments(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return getUserAppointments(userId).map((appointments) {
      return appointments.where((apt) => apt.appointmentTime <= now).toList();
    });
  }

  /// Get all appointments for a doctor
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      final List<AppointmentModel> appointments = [];
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

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final appointmentData = Map<String, dynamic>.from(entry.value as Map);
          
          // Fetch user name if not already present (for patient name)
          final userId = appointmentData['userId'] as String;
          try {
             final userSnapshot = await _db.child('users').child(userId).get();
             if (userSnapshot.exists) {
               final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
               // Note: AppointmentModel might not support storing patientName directly.
             }
          } catch (e) {
            print('Error fetching user name: $e');
          }
          
          appointments.add(AppointmentModel.fromJson(appointmentData));
        }
      }
      // Sort by appointmentTime descending
      appointments.sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));
      return appointments;
    });
  }

  /// Create new appointment
  Future<String?> createAppointment({
    required String userId,
    required String doctorId,
    String? doctorName,
    required int appointmentTime,
    required String location,
    String? department,
    String? building,
    String? floor,
    String? room,
    required String reason,
    String? notes,
  }) async {
    try {
      final appointmentRef = _db.child('appointments').push();
      final appointmentId = appointmentRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final appointment = AppointmentModel(
        appointmentId: appointmentId,
        userId: userId,
        doctorId: doctorId,
        doctorName: doctorName,
        appointmentTime: appointmentTime,
        location: location,
        department: department,
        building: building,
        floor: floor,
        room: room,
        reason: reason,
        status: 'pending',
        createdBy: userId,
        createdAt: now,
        notes: notes,
      );

      await appointmentRef.set(appointment.toJson());
      return appointmentId;
    } catch (e) {
      print('Error creating appointment: $e');
      return null;
    }
  }

  /// Confirm appointment
  Future<bool> confirmAppointment(String appointmentId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': now,
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      print('Error confirming appointment: $e');
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'cancelledAt': now,
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Reschedule appointment
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required int newTime,
    String? reason,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'appointmentTime': newTime,
        'status': 'confirmed',
        'rescheduleReason': reason,
        'rescheduledAt': now,
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      print('Error rescheduling appointment: $e');
      return false;
    }
  }

  /// Propose new time for appointment
  Future<bool> proposeReschedule({
    required String appointmentId,
    required int proposedTime,
    required String userId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'proposedTime': proposedTime,
        'proposedByUser': userId,
        'rescheduleReason': reason,
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      print('Error proposing reschedule: $e');
      return false;
    }
  }

  /// Complete appointment
  Future<bool> completeAppointment(String appointmentId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'status': 'completed',
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      print('Error completing appointment: $e');
      return false;
    }
  }

  /// Get appointment by ID
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      final snapshot = await _db.child('appointments').child(appointmentId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return AppointmentModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting appointment: $e');
      return null;
    }
  }

  /// Lấy lịch hẹn theo trạng thái cho bác sĩ
  /// Requirements: 2.1
  Stream<List<AppointmentModel>> getAppointmentsByStatus(
    String doctorId,
    String status,
  ) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      final List<AppointmentModel> appointments = [];
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

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final appointmentData = Map<String, dynamic>.from(entry.value as Map);
          final appointment = AppointmentModel.fromJson(appointmentData);
          
          // Lọc theo trạng thái
          if (appointment.status == status) {
            // Fetch patient name
            final userId = appointmentData['userId'] as String?;
            if (userId != null) {
              try {
                final userSnapshot = await _db.child('users').child(userId).get();
                if (userSnapshot.exists) {
                  final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                  appointmentData['patientName'] = userData['name'] as String? ?? 'Bệnh nhân';
                }
              } catch (e) {
                print('Error fetching patient name: $e');
              }
            }
            appointments.add(AppointmentModel.fromJson(appointmentData));
          }
        }
      }
      // Sắp xếp theo thời gian hẹn
      appointments.sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
      return appointments;
    });
  }

  /// Lấy lịch hẹn hôm nay cho bác sĩ
  /// Requirements: 2.1
  Stream<List<AppointmentModel>> getTodayAppointments(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    return getDoctorAppointments(doctorId).map((appointments) {
      return appointments.where((apt) {
        return apt.appointmentTime >= startOfDay &&
            apt.appointmentTime <= endOfDay &&
            (apt.status == 'confirmed' || apt.status == 'pending');
      }).toList()
        ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
    });
  }

  /// Lấy lịch hẹn sắp tới cho bác sĩ (sau hôm nay)
  /// Requirements: 2.1
  Stream<List<AppointmentModel>> getUpcomingDoctorAppointments(String doctorId) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    return getDoctorAppointments(doctorId).map((appointments) {
      return appointments.where((apt) {
        return apt.appointmentTime > endOfDay &&
            (apt.status == 'confirmed' || apt.status == 'pending');
      }).toList()
        ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
    });
  }

  /// Lấy yêu cầu lịch hẹn đang chờ xác nhận
  /// Requirements: 2.2
  Stream<List<AppointmentModel>> getPendingRequests(String doctorId) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      final List<AppointmentModel> appointments = [];
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

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final appointmentData = Map<String, dynamic>.from(entry.value as Map);
          final appointment = AppointmentModel.fromJson(appointmentData);

          // Chỉ lấy các yêu cầu đang chờ
          if (appointment.status == 'pending') {
            // Fetch patient name
            final userId = appointmentData['userId'] as String?;
            if (userId != null) {
              try {
                final userSnapshot = await _db.child('users').child(userId).get();
                if (userSnapshot.exists) {
                  final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                  appointmentData['patientName'] = userData['name'] as String? ?? 'Bệnh nhân';
                  appointmentData['patientPhone'] = userData['phone'] as String?;
                }
              } catch (e) {
                print('Error fetching patient info: $e');
              }
            }
            appointments.add(AppointmentModel.fromJson(appointmentData));
          }
        }
      }
      // Sắp xếp theo thời gian tạo (mới nhất trước)
      appointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return appointments;
    });
  }

  /// Từ chối lịch hẹn với lý do
  /// Requirements: 2.4
  Future<bool> rejectAppointment(String appointmentId, String reason) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.child('appointments').child(appointmentId).update({
        'status': 'rejected',
        'rejectReason': reason,
        'rejectedAt': now,
        'updatedAt': now,
      });

      // Gửi notification cho bệnh nhân
      try {
        final snapshot = await _db.child('appointments').child(appointmentId).get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final userId = data['userId'] as String?;
          
          if (userId != null) {
            final notificationService = EnhancedNotificationService();
            await notificationService.createNotification(
              userId: userId,
              title: 'Lịch hẹn bị từ chối',
              message: 'Bác sĩ đã từ chối lịch hẹn của bạn. Lý do: $reason',
              type: 'appointment_rejected',
              data: {'appointmentId': appointmentId},
            );
          }
        }
      } catch (e) {
        print('Error sending rejection notification: $e');
      }
      
      return true;
    } catch (e) {
      print('Error rejecting appointment: $e');
      return false;
    }
  }

  /// Lấy chi tiết lịch hẹn với thông tin bệnh nhân đầy đủ
  /// Requirements: 2.7
  Future<AppointmentDetailModel?> getAppointmentDetail(String appointmentId) async {
    try {
      // Lấy thông tin lịch hẹn
      final appointmentSnapshot = await _db.child('appointments').child(appointmentId).get();
      if (!appointmentSnapshot.exists) {
        return null;
      }

      final appointmentData = Map<String, dynamic>.from(appointmentSnapshot.value as Map);
      final appointment = AppointmentModel.fromJson(appointmentData);

      // Lấy thông tin bệnh nhân
      UserModel? patient;
      final userId = appointment.userId;
      final userSnapshot = await _db.child('users').child(userId).get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        patient = UserModel.fromJson(userData);
      }

      // Lấy lịch sử lịch hẹn trước đó của bệnh nhân với bác sĩ này
      final List<AppointmentModel> previousAppointments = [];
      final previousSnapshot = await _db
          .child('appointments')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (previousSnapshot.exists && previousSnapshot.value != null) {
        final dynamic value = previousSnapshot.value;
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

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final prevData = Map<String, dynamic>.from(entry.value as Map);
          final prevAppointment = AppointmentModel.fromJson(prevData);
          
          // Chỉ lấy các lịch hẹn đã hoàn thành và không phải lịch hẹn hiện tại
          if (prevAppointment.appointmentId != appointmentId &&
              prevAppointment.doctorId == appointment.doctorId &&
              prevAppointment.status == 'completed') {
            previousAppointments.add(prevAppointment);
          }
        }
        // Sắp xếp theo thời gian mới nhất
        previousAppointments.sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));
      }

      // Lấy hồ sơ sức khỏe gần đây của bệnh nhân
      final List<HealthRecordModel> healthRecords = [];
      final healthSnapshot = await _db
          .child('healthRecords')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(5)
          .get();

      if (healthSnapshot.exists && healthSnapshot.value != null) {
        final dynamic value = healthSnapshot.value;
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

        for (var entry in data.entries) {
          if (entry.value == null) continue;
          final recordData = Map<String, dynamic>.from(entry.value as Map);
          healthRecords.add(HealthRecordModel.fromJson(recordData));
        }
        // Sắp xếp theo thời gian mới nhất
        healthRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      }

      return AppointmentDetailModel(
        appointment: appointment,
        patient: patient,
        previousAppointments: previousAppointments,
        healthRecords: healthRecords,
      );
    } catch (e) {
      print('Error getting appointment detail: $e');
      return null;
    }
  }
}
