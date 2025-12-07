import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/user_model.dart';
import '../data/models/health_record_model.dart';
import '../data/models/appointment_model.dart';

/// Model cho hồ sơ bệnh nhân chi tiết
class PatientProfile {
  final UserModel user;
  final List<HealthRecordModel> healthRecords;
  final List<AppointmentModel> appointments;
  final List<PatientNote> notes;
  final String? healthStatus; // 'high_risk', 'warning', 'stable'

  PatientProfile({
    required this.user,
    this.healthRecords = const [],
    this.appointments = const [],
    this.notes = const [],
    this.healthStatus,
  });
}

/// Model cho ghi chú bệnh nhân
class PatientNote {
  final String noteId;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String content;
  final int createdAt;

  PatientNote({
    required this.noteId,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.content,
    required this.createdAt,
  });

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      noteId: json['noteId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}


/// Model tóm tắt bệnh nhân cho danh sách
class PatientSummary {
  final String id;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? healthStatus;
  final int? lastAppointmentTime;
  final HealthRecordModel? latestHealthRecord;

  PatientSummary({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.healthStatus,
    this.lastAppointmentTime,
    this.latestHealthRecord,
  });
}

/// Service quản lý bệnh nhân cho bác sĩ
/// Implements Requirements 8.1, 8.2, 8.3, 8.4, 8.5
class PatientService {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Lấy danh sách bệnh nhân của bác sĩ (đã có lịch hẹn)
  /// Requirements: 8.1
  Stream<List<PatientSummary>> getDoctorPatients(String doctorId) {
    return _db
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      final Map<String, PatientSummary> uniquePatients = {};

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
          final userId = appointmentData['userId'] as String?;
          final appointmentTime = appointmentData['appointmentTime'] as int? ?? 0;

          if (userId != null && !uniquePatients.containsKey(userId)) {
            // Fetch user details
            try {
              final userSnapshot = await _db.child('users').child(userId).get();
              if (userSnapshot.exists && userSnapshot.value != null) {
                final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                
                // Fetch latest health record
                HealthRecordModel? latestRecord;
                String? healthStatus;
                final healthSnapshot = await _db
                    .child('healthRecords')
                    .orderByChild('userId')
                    .equalTo(userId)
                    .limitToLast(1)
                    .get();

                if (healthSnapshot.exists && healthSnapshot.value != null) {
                  final healthData = healthSnapshot.value;
                  if (healthData is Map) {
                    final firstEntry = healthData.entries.first;
                    final recordData = Map<String, dynamic>.from(firstEntry.value as Map);
                    latestRecord = HealthRecordModel.fromJson(recordData);
                    healthStatus = _calculateHealthStatus(latestRecord);
                  }
                }

                uniquePatients[userId] = PatientSummary(
                  id: userId,
                  name: userData['name'] as String? ?? 'Bệnh nhân',
                  phone: userData['phone'] as String?,
                  avatarUrl: userData['photoURL'] as String?,
                  healthStatus: healthStatus ?? 'stable',
                  lastAppointmentTime: appointmentTime,
                  latestHealthRecord: latestRecord,
                );
              }
            } catch (e) {
              print('Error fetching patient details: $e');
            }
          } else if (userId != null && uniquePatients.containsKey(userId)) {
            // Update last appointment time if newer
            final existing = uniquePatients[userId]!;
            if (appointmentTime > (existing.lastAppointmentTime ?? 0)) {
              uniquePatients[userId] = PatientSummary(
                id: existing.id,
                name: existing.name,
                phone: existing.phone,
                avatarUrl: existing.avatarUrl,
                healthStatus: existing.healthStatus,
                lastAppointmentTime: appointmentTime,
                latestHealthRecord: existing.latestHealthRecord,
              );
            }
          }
        }
      }

      // Sort by last appointment time (most recent first)
      final patients = uniquePatients.values.toList();
      patients.sort((a, b) => 
        (b.lastAppointmentTime ?? 0).compareTo(a.lastAppointmentTime ?? 0));
      return patients;
    });
  }


  /// Tìm kiếm bệnh nhân theo tên, phone, hoặc ID
  /// Requirements: 8.2
  /// Property 11: Patient Search Filtering
  Future<List<PatientSummary>> searchPatients(
    String doctorId,
    String query,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase().trim();
    final List<PatientSummary> results = [];

    try {
      // First get all patients of this doctor
      final appointmentsSnapshot = await _db
          .child('appointments')
          .orderByChild('doctorId')
          .equalTo(doctorId)
          .get();

      if (!appointmentsSnapshot.exists || appointmentsSnapshot.value == null) {
        return [];
      }

      final dynamic value = appointmentsSnapshot.value;
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

      // Get unique patient IDs
      final Set<String> patientIds = {};
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final appointmentData = Map<String, dynamic>.from(entry.value as Map);
        final userId = appointmentData['userId'] as String?;
        if (userId != null) {
          patientIds.add(userId);
        }
      }

      // Search through patients
      for (final patientId in patientIds) {
        final userSnapshot = await _db.child('users').child(patientId).get();
        if (!userSnapshot.exists || userSnapshot.value == null) continue;

        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final name = (userData['name'] as String? ?? '').toLowerCase();
        final phone = (userData['phone'] as String? ?? '').toLowerCase();
        final id = patientId.toLowerCase();

        // Check if query matches name, phone, or ID
        if (name.contains(queryLower) ||
            phone.contains(queryLower) ||
            id.contains(queryLower)) {
          // Fetch latest health record
          HealthRecordModel? latestRecord;
          String? healthStatus;
          final healthSnapshot = await _db
              .child('healthRecords')
              .orderByChild('userId')
              .equalTo(patientId)
              .limitToLast(1)
              .get();

          if (healthSnapshot.exists && healthSnapshot.value != null) {
            final healthData = healthSnapshot.value;
            if (healthData is Map) {
              final firstEntry = healthData.entries.first;
              final recordData = Map<String, dynamic>.from(firstEntry.value as Map);
              latestRecord = HealthRecordModel.fromJson(recordData);
              healthStatus = _calculateHealthStatus(latestRecord);
            }
          }

          results.add(PatientSummary(
            id: patientId,
            name: userData['name'] as String? ?? 'Bệnh nhân',
            phone: userData['phone'] as String?,
            avatarUrl: userData['photoURL'] as String?,
            healthStatus: healthStatus ?? 'stable',
            latestHealthRecord: latestRecord,
          ));
        }
      }
    } catch (e) {
      print('Error searching patients: $e');
    }

    return results;
  }

  /// Lấy hồ sơ bệnh nhân chi tiết
  /// Requirements: 8.3
  Future<PatientProfile?> getPatientProfile(String patientId) async {
    try {
      // Fetch user info
      final userSnapshot = await _db.child('users').child(patientId).get();
      if (!userSnapshot.exists || userSnapshot.value == null) {
        return null;
      }

      final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      final user = UserModel.fromJson(userData);

      // Fetch health records
      final healthRecords = await _fetchHealthRecords(patientId);

      // Fetch appointments
      final appointments = await _fetchAppointments(patientId);

      // Fetch notes
      final notes = await _fetchPatientNotes(patientId);

      // Calculate health status
      String? healthStatus;
      if (healthRecords.isNotEmpty) {
        healthStatus = _calculateHealthStatus(healthRecords.first);
      }

      return PatientProfile(
        user: user,
        healthRecords: healthRecords,
        appointments: appointments,
        notes: notes,
        healthStatus: healthStatus ?? 'stable',
      );
    } catch (e) {
      print('Error getting patient profile: $e');
      return null;
    }
  }


  /// Lấy lịch sử sức khỏe của bệnh nhân
  /// Requirements: 8.4
  Stream<List<HealthRecordModel>> getPatientHealthHistory(String patientId) {
    return _db
        .child('healthRecords')
        .orderByChild('userId')
        .equalTo(patientId)
        .onValue
        .map((event) {
      final List<HealthRecordModel> records = [];
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
          final recordData = Map<String, dynamic>.from(entry.value as Map);
          records.add(HealthRecordModel.fromJson(recordData));
        }
      }
      // Sort by recorded time (newest first)
      records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return records;
    });
  }

  /// Thêm ghi chú cho bệnh nhân
  /// Requirements: 8.5
  Future<bool> addPatientNote({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String content,
  }) async {
    try {
      final noteRef = _db.child('patient_notes').push();
      final noteId = noteRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final note = PatientNote(
        noteId: noteId,
        patientId: patientId,
        doctorId: doctorId,
        doctorName: doctorName,
        content: content,
        createdAt: now,
      );

      await noteRef.set(note.toJson());
      return true;
    } catch (e) {
      print('Error adding patient note: $e');
      return false;
    }
  }

  /// Lấy ghi chú của bệnh nhân
  Stream<List<PatientNote>> getPatientNotes(String patientId) {
    return _db
        .child('patient_notes')
        .orderByChild('patientId')
        .equalTo(patientId)
        .onValue
        .map((event) {
      final List<PatientNote> notes = [];
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
          final noteData = Map<String, dynamic>.from(entry.value as Map);
          notes.add(PatientNote.fromJson(noteData));
        }
      }
      // Sort by created time (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    });
  }

  /// Xóa ghi chú
  Future<bool> deletePatientNote(String noteId) async {
    try {
      await _db.child('patient_notes').child(noteId).remove();
      return true;
    } catch (e) {
      print('Error deleting patient note: $e');
      return false;
    }
  }

  // Helper methods

  Future<List<HealthRecordModel>> _fetchHealthRecords(String patientId) async {
    final List<HealthRecordModel> records = [];
    try {
      final snapshot = await _db
          .child('healthRecords')
          .orderByChild('userId')
          .equalTo(patientId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final dynamic value = snapshot.value;
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
          records.add(HealthRecordModel.fromJson(recordData));
        }
      }
      records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    } catch (e) {
      print('Error fetching health records: $e');
    }
    return records;
  }

  Future<List<AppointmentModel>> _fetchAppointments(String patientId) async {
    final List<AppointmentModel> appointments = [];
    try {
      final snapshot = await _db
          .child('appointments')
          .orderByChild('userId')
          .equalTo(patientId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final dynamic value = snapshot.value;
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
          appointments.add(AppointmentModel.fromJson(appointmentData));
        }
      }
      appointments.sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));
    } catch (e) {
      print('Error fetching appointments: $e');
    }
    return appointments;
  }


  Future<List<PatientNote>> _fetchPatientNotes(String patientId) async {
    final List<PatientNote> notes = [];
    try {
      final snapshot = await _db
          .child('patient_notes')
          .orderByChild('patientId')
          .equalTo(patientId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final dynamic value = snapshot.value;
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
          final noteData = Map<String, dynamic>.from(entry.value as Map);
          notes.add(PatientNote.fromJson(noteData));
        }
      }
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error fetching patient notes: $e');
    }
    return notes;
  }

  /// Calculate health status based on latest health record
  String _calculateHealthStatus(HealthRecordModel record) {
    // Check blood pressure
    if (record.systolicBP != null && record.diastolicBP != null) {
      if (record.systolicBP! >= 180 || record.diastolicBP! >= 120) {
        return 'high_risk';
      }
      if (record.systolicBP! >= 140 || record.diastolicBP! >= 90) {
        return 'warning';
      }
    }

    // Check heart rate
    if (record.heartRate != null) {
      if (record.heartRate! > 120 || record.heartRate! < 50) {
        return 'high_risk';
      }
      if (record.heartRate! > 100 || record.heartRate! < 60) {
        return 'warning';
      }
    }

    // Check blood sugar
    if (record.bloodSugar != null) {
      if (record.bloodSugar! > 200 || record.bloodSugar! < 70) {
        return 'high_risk';
      }
      if (record.bloodSugar! > 140) {
        return 'warning';
      }
    }

    return 'stable';
  }

  /// Static method for search filtering (pure function for testing)
  /// Property 11: Patient Search Filtering
  /// Validates: Requirements 8.2
  static bool matchesSearchQuery(
    String query,
    String name,
    String? phone,
    String id,
  ) {
    if (query.isEmpty) return true;
    
    final queryLower = query.toLowerCase().trim();
    final nameLower = name.toLowerCase();
    final phoneLower = (phone ?? '').toLowerCase();
    final idLower = id.toLowerCase();

    return nameLower.contains(queryLower) ||
        phoneLower.contains(queryLower) ||
        idLower.contains(queryLower);
  }
}
