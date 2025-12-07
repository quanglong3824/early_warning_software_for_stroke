import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'family_service.dart';
import 'enhanced_notification_service.dart';
import 'health_record_service.dart';

/// Model for SOS case with priority calculation
class SOSCaseModel {
  final String sosId;
  final String patientId;
  final String patientName;
  final String status;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String? acknowledgedByName;
  final String? notes;
  final int priority;
  final int waitTimeMinutes;

  SOSCaseModel({
    required this.sosId,
    required this.patientId,
    required this.patientName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.notes,
    required this.priority,
    required this.waitTimeMinutes,
  });

  factory SOSCaseModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    final createdAt = createdAtStr != null 
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    
    final acknowledgedAtStr = json['acknowledgedAt'] as String?;
    final acknowledgedAt = acknowledgedAtStr != null 
        ? DateTime.tryParse(acknowledgedAtStr)
        : null;

    // Calculate wait time in minutes
    final waitTimeMinutes = DateTime.now().difference(createdAt).inMinutes;
    
    // Calculate priority: higher = more urgent
    // Base priority on wait time and status
    int priority = waitTimeMinutes;
    final status = json['status'] as String? ?? 'pending';
    if (status == 'pending') {
      priority += 100; // Pending cases are highest priority
    } else if (status == 'acknowledged') {
      priority += 50;
    }

    final location = json['userLocation'] as Map?;
    
    return SOSCaseModel(
      sosId: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? json['userId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Bệnh nhân',
      status: status,
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0.0,
      address: location?['address'] as String? ?? 'Không xác định',
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedByName: json['acknowledgedByName'] as String?,
      notes: json['notes'] as String?,
      priority: priority,
      waitTimeMinutes: waitTimeMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': sosId,
    'patientId': patientId,
    'patientName': patientName,
    'status': status,
    'userLocation': {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    },
    'createdAt': createdAt.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'acknowledgedBy': acknowledgedBy,
    'acknowledgedByName': acknowledgedByName,
    'notes': notes,
  };
}

/// Detailed SOS case model with patient medical history
class SOSCaseDetailModel {
  final SOSCaseModel sosCase;
  final Map<String, dynamic>? patientInfo;
  final List<Map<String, dynamic>> medicalHistory;
  final List<Map<String, dynamic>> emergencyContacts;

  SOSCaseDetailModel({
    required this.sosCase,
    this.patientInfo,
    this.medicalHistory = const [],
    this.emergencyContacts = const [],
  });
}

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  final _db = FirebaseDatabase.instance;
  final _locationService = LocationService();
  // ignore: unused_field
  final _notificationService = NotificationService();
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _enhancedNotificationService = EnhancedNotificationService();
  // ignore: unused_field - kept for future use in medical record creation
  final _healthRecordService = HealthRecordService();

  /// Create SOS request
  Future<String?> createSOSRequest({
    required String patientId,
    String? patientName,
    String? notes,
  }) async {
    try {
      // Get current user
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // Get current location
      Position? position = await _locationService.getCurrentLocation();
      if (position == null) throw Exception('Cannot get location');

      // Get address
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Find nearest hospital (mock data - should query from database)
      String nearestHospitalId = await _findNearestHospital(
        position.latitude,
        position.longitude,
      );

      // Create SOS request
      final sosRef = _db.ref('sos_requests').push();
      final sosId = sosRef.key!;

      await sosRef.set({
        'id': sosId,
        'userId': userId,
        'patientId': patientId,
        'patientName': patientName ?? 'Bệnh nhân',
        'userLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
        },
        'assignedHospitalId': nearestHospitalId,
        'status': 'pending', // pending, acknowledged, dispatched, resolved
        'notes': notes,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Send notifications to family members
      await _notifyFamilyMembers(userId, sosId, address);

      // Send notification to hospital (mock)
      await _notifyHospital(nearestHospitalId, sosId);

      // Start auto-progression (simulate real emergency response)
      _startAutoProgression(sosId);

      return sosId;
    } catch (e) {
      print('Error creating SOS request: $e');
      return null;
    }
  }

  /// Auto-progress SOS status (simulate emergency response)
  void _startAutoProgression(String sosId) {
    // After 30s: pending → acknowledged
    Future.delayed(const Duration(seconds: 30), () async {
      try {
        final sos = await getSOSRequest(sosId);
        if (sos != null && sos['status'] == 'pending') {
          await updateSOSStatus(sosId, 'acknowledged');
          print('✅ SOS $sosId: pending → acknowledged');
        }
      } catch (e) {
        print('Error auto-progressing to acknowledged: $e');
      }
    });

    // After 2 minutes: acknowledged → dispatched
    Future.delayed(const Duration(minutes: 2), () async {
      try {
        final sos = await getSOSRequest(sosId);
        if (sos != null && sos['status'] == 'acknowledged') {
          await updateSOSStatus(sosId, 'dispatched');
          print('✅ SOS $sosId: acknowledged → dispatched');
        }
      } catch (e) {
        print('Error auto-progressing to dispatched: $e');
      }
    });

    // After 10 minutes: dispatched → resolved
    Future.delayed(const Duration(minutes: 10), () async {
      try {
        final sos = await getSOSRequest(sosId);
        if (sos != null && sos['status'] == 'dispatched') {
          await updateSOSStatus(sosId, 'resolved');
          print('✅ SOS $sosId: dispatched → resolved');
        }
      } catch (e) {
        print('Error auto-progressing to resolved: $e');
      }
    });
  }

  /// Update SOS status and notify family members
  Future<void> updateSOSStatus(String sosId, String status, {String? doctorName}) async {
    try {
      await _db.ref('sos_requests/$sosId').update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
        if (status == 'acknowledged') 'acknowledgedAt': DateTime.now().toIso8601String(),
        if (status == 'dispatched') 'dispatchedAt': DateTime.now().toIso8601String(),
        if (status == 'resolved') 'resolvedAt': DateTime.now().toIso8601String(),
        if (doctorName != null) 'acknowledgedBy': doctorName,
      });

      // Get the SOS request to find the user ID
      final sosSnapshot = await _db.ref('sos_requests/$sosId').get();
      if (sosSnapshot.exists) {
        final sosData = Map<String, dynamic>.from(sosSnapshot.value as Map);
        final userId = sosData['userId'] as String?;
        
        if (userId != null) {
          // Notify family members about status change
          await notifyFamilyOnSOSStatusChange(
            userId: userId,
            sosId: sosId,
            newStatus: status,
            doctorName: doctorName,
          );
        }
      }
    } catch (e) {
      print('Error updating SOS status: $e');
    }
  }

  /// Get SOS request by ID
  Future<Map<String, dynamic>?> getSOSRequest(String sosId) async {
    try {
      final snapshot = await _db.ref('sos_requests/$sosId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting SOS request: $e');
      return null;
    }
  }

  /// Listen to SOS request changes
  Stream<Map<String, dynamic>?> listenToSOSRequest(String sosId) {
    return _db.ref('sos_requests/$sosId').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Get user's SOS history
  Stream<List<Map<String, dynamic>>> getUserSOSHistory(String userId) {
    return _db
        .ref('sos_requests')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return data.entries
            .map((e) => Map<String, dynamic>.from(e.value as Map))
            .toList()
          ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      }
      return [];
    });
  }

  /// Get active SOS requests (for doctors)
  Stream<List<Map<String, dynamic>>> getActiveSOSRequests() {
    return _db
        .ref('sos_requests')
        .orderByChild('status')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return data.entries
            .map((e) => Map<String, dynamic>.from(e.value as Map))
            .where((sos) => sos['status'] != 'resolved')
            .toList()
          ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      }
      return [];
    });
  }

  /// Cancel SOS request
  Future<void> cancelSOSRequest(String sosId) async {
    try {
      await updateSOSStatus(sosId, 'cancelled');
    } catch (e) {
      print('Error cancelling SOS: $e');
    }
  }

  /// Find nearest hospital from Firebase database
  Future<String> _findNearestHospital(double lat, double lng) async {
    try {
      // Query hospitals from Firebase
      final snapshot = await _db.ref('hospitals').get();
      
      if (!snapshot.exists) {
        print('⚠️ No hospitals found in database, using fallback');
        return 'hospital_default';
      }

      final hospitalsData = Map<String, dynamic>.from(snapshot.value as Map);
      String? nearestHospitalId;
      double minDistance = double.infinity;

      // Calculate distance to each hospital
      for (var entry in hospitalsData.entries) {
        final hospitalData = Map<String, dynamic>.from(entry.value as Map);
        final hospitalLat = hospitalData['latitude'] as double?;
        final hospitalLng = hospitalData['longitude'] as double?;

        if (hospitalLat != null && hospitalLng != null) {
          final distance = Geolocator.distanceBetween(
            lat,
            lng,
            hospitalLat,
            hospitalLng,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestHospitalId = entry.key;
          }
        }
      }

      if (nearestHospitalId != null) {
        print('✅ Found nearest hospital: $nearestHospitalId (${(minDistance / 1000).toStringAsFixed(2)} km)');
        return nearestHospitalId;
      }

      print('⚠️ No hospital with coordinates found, using fallback');
      return hospitalsData.keys.first;
    } catch (e) {
      print('Error finding nearest hospital: $e');
      return 'hospital_default';
    }
  }

  /// Notify all family members about SOS
  /// Requirements: 6.2 - Real-time notification broadcast to all family members
  Future<void> _notifyFamilyMembers(String userId, String sosId, String address) async {
    try {
      // Get all family member IDs using the FamilyService
      final familyMemberIds = await _familyService.getFamilyMemberIds(userId);
      
      if (familyMemberIds.isEmpty) {
        print('⚠️ No family members to notify for SOS');
        return;
      }

      // Get user name for notification
      final userSnapshot = await _db.ref('users/$userId').get();
      String userName = 'Người thân của bạn';
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        userName = userData['name'] as String? ?? 'Người thân của bạn';
      }

      print('📢 Broadcasting SOS notification to ${familyMemberIds.length} family members');

      // Send notification to all family members
      await notifyFamilyMembersOnSOS(
        userId: userId,
        userName: userName,
        sosId: sosId,
        address: address,
        familyMemberIds: familyMemberIds,
      );

      print('✅ SOS notifications sent to all family members');
    } catch (e) {
      print('❌ Error notifying family: $e');
    }
  }

  /// Broadcast SOS notification to all family members
  /// Requirements: 6.2
  Future<void> notifyFamilyMembersOnSOS({
    required String userId,
    required String userName,
    required String sosId,
    required String address,
    required List<String> familyMemberIds,
  }) async {
    try {
      final title = '🚨 Cảnh báo SOS khẩn cấp!';
      final message = '$userName đã kích hoạt SOS tại $address';

      // Send notification to each family member
      for (final memberId in familyMemberIds) {
        // Create database notification
        await _enhancedNotificationService.createNotification(
          userId: memberId,
          type: 'sos_alert',
          title: title,
          message: message,
          data: {
            'sosId': sosId,
            'userId': userId,
            'userName': userName,
            'address': address,
            'route': '/sos-status',
            'targetId': sosId,
          },
          sendPush: true,
        );

        // Also create a direct notification in the database for real-time updates
        await _db.ref('notifications/$memberId').push().set({
          'type': 'sos_alert',
          'title': title,
          'message': message,
          'data': {
            'sosId': sosId,
            'userId': userId,
            'userName': userName,
            'address': address,
          },
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
          'priority': 'high',
        });
      }

      print('✅ SOS broadcast completed for ${familyMemberIds.length} members');
    } catch (e) {
      print('❌ Error broadcasting SOS to family: $e');
    }
  }

  /// Notify family members when SOS status changes (acknowledged, dispatched, resolved)
  Future<void> notifyFamilyOnSOSStatusChange({
    required String userId,
    required String sosId,
    required String newStatus,
    String? doctorName,
  }) async {
    try {
      final familyMemberIds = await _familyService.getFamilyMemberIds(userId);
      
      if (familyMemberIds.isEmpty) return;

      String title;
      String message;

      switch (newStatus) {
        case 'acknowledged':
          title = '✅ SOS đã được tiếp nhận';
          message = doctorName != null
              ? 'Bác sĩ $doctorName đã tiếp nhận yêu cầu SOS của người thân bạn'
              : 'Yêu cầu SOS của người thân bạn đã được tiếp nhận';
          break;
        case 'dispatched':
          title = '🚑 Đội cấp cứu đang đến';
          message = 'Đội cấp cứu đang trên đường đến hỗ trợ người thân của bạn';
          break;
        case 'resolved':
          title = '✅ SOS đã xử lý xong';
          message = 'Yêu cầu SOS của người thân bạn đã được xử lý hoàn tất';
          break;
        default:
          title = 'Cập nhật SOS';
          message = 'Trạng thái SOS của người thân bạn đã được cập nhật';
      }

      for (final memberId in familyMemberIds) {
        await _enhancedNotificationService.createNotification(
          userId: memberId,
          type: 'sos_update',
          title: title,
          message: message,
          data: {
            'sosId': sosId,
            'userId': userId,
            'status': newStatus,
            'route': '/sos-status',
            'targetId': sosId,
          },
          sendPush: true,
        );
      }
    } catch (e) {
      print('Error notifying family on SOS status change: $e');
    }
  }

  /// Notify hospital
  Future<void> _notifyHospital(String hospitalId, String sosId) async {
    try {
      // Create notification for hospital/doctors
      await _db.ref('hospital_notifications/$hospitalId').push().set({
        'type': 'new_sos',
        'sosId': sosId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error notifying hospital: $e');
    }
  }

  // ===== Doctor-specific methods =====

  /// Get SOS cases sorted by priority (for doctors)
  /// Requirements: 3.1, 3.6
  Stream<List<SOSCaseModel>> getSOSCasesByPriority() {
    return _db
        .ref('sos_requests')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <SOSCaseModel>[];
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final cases = <SOSCaseModel>[];
      
      data.forEach((key, value) {
        final sosData = Map<String, dynamic>.from(value as Map);
        final status = sosData['status'] as String? ?? 'pending';
        
        // Only include active cases (not resolved or cancelled)
        if (status != 'resolved' && status != 'cancelled') {
          cases.add(SOSCaseModel.fromJson(sosData));
        }
      });
      
      // Sort by priority (higher priority first)
      cases.sort((a, b) => b.priority.compareTo(a.priority));
      
      return cases;
    });
  }

  /// Get detailed SOS case information including patient medical history
  /// Requirements: 3.3
  Future<SOSCaseDetailModel?> getSOSCaseDetail(String sosId) async {
    try {
      // Get SOS request
      final sosSnapshot = await _db.ref('sos_requests/$sosId').get();
      if (!sosSnapshot.exists) return null;
      
      final sosData = Map<String, dynamic>.from(sosSnapshot.value as Map);
      final sosCase = SOSCaseModel.fromJson(sosData);
      
      // Get patient info
      final patientId = sosCase.patientId;
      Map<String, dynamic>? patientInfo;
      
      if (patientId.isNotEmpty) {
        final patientSnapshot = await _db.ref('users/$patientId').get();
        if (patientSnapshot.exists) {
          patientInfo = Map<String, dynamic>.from(patientSnapshot.value as Map);
        }
      }
      
      // Get medical history (health records)
      final medicalHistory = <Map<String, dynamic>>[];
      if (patientId.isNotEmpty) {
        final healthSnapshot = await _db
            .ref('health_records/$patientId')
            .orderByChild('recordedAt')
            .limitToLast(10)
            .get();
        
        if (healthSnapshot.exists) {
          final healthData = Map<String, dynamic>.from(healthSnapshot.value as Map);
          healthData.forEach((key, value) {
            medicalHistory.add(Map<String, dynamic>.from(value as Map));
          });
          // Sort by recordedAt descending
          medicalHistory.sort((a, b) {
            final aTime = a['recordedAt'] as int? ?? 0;
            final bTime = b['recordedAt'] as int? ?? 0;
            return bTime.compareTo(aTime);
          });
        }
      }
      
      // Get emergency contacts (family members)
      final emergencyContacts = <Map<String, dynamic>>[];
      if (patientId.isNotEmpty) {
        final familyMemberIds = await _familyService.getFamilyMemberIds(patientId);
        
        for (final memberId in familyMemberIds) {
          final memberSnapshot = await _db.ref('users/$memberId').get();
          if (memberSnapshot.exists) {
            final memberData = Map<String, dynamic>.from(memberSnapshot.value as Map);
            emergencyContacts.add({
              'id': memberId,
              'name': memberData['name'] ?? 'Không rõ',
              'phone': memberData['phone'] ?? '',
              'relationship': 'Người thân',
            });
          }
        }
      }
      
      return SOSCaseDetailModel(
        sosCase: sosCase,
        patientInfo: patientInfo,
        medicalHistory: medicalHistory,
        emergencyContacts: emergencyContacts,
      );
    } catch (e) {
      print('Error getting SOS case detail: $e');
      return null;
    }
  }

  /// Doctor acknowledges an SOS case
  /// Requirements: 3.2
  Future<bool> acknowledgeSOSCase(String sosId, String doctorId, String doctorName) async {
    try {
      // Get current SOS status
      final sosSnapshot = await _db.ref('sos_requests/$sosId').get();
      if (!sosSnapshot.exists) {
        print('SOS case not found: $sosId');
        return false;
      }
      
      final sosData = Map<String, dynamic>.from(sosSnapshot.value as Map);
      final currentStatus = sosData['status'] as String? ?? 'pending';
      
      // Validate status transition: only pending can be acknowledged
      if (currentStatus != 'pending') {
        print('Invalid status transition: $currentStatus -> acknowledged');
        return false;
      }
      
      // Update SOS status
      await _db.ref('sos_requests/$sosId').update({
        'status': 'acknowledged',
        'acknowledgedAt': DateTime.now().toIso8601String(),
        'acknowledgedBy': doctorId,
        'acknowledgedByName': doctorName,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Get patient ID for notifications
      final patientId = sosData['userId'] as String?;
      
      if (patientId != null) {
        // Notify patient
        await _enhancedNotificationService.sendSOSNotification(
          userId: patientId,
          sosId: sosId,
          status: 'acknowledged',
          doctorName: doctorName,
        );
        
        // Notify family members
        await notifyFamilyOnSOSStatusChange(
          userId: patientId,
          sosId: sosId,
          newStatus: 'acknowledged',
          doctorName: doctorName,
        );
      }
      
      print('✅ SOS $sosId acknowledged by $doctorName');
      return true;
    } catch (e) {
      print('Error acknowledging SOS case: $e');
      return false;
    }
  }

  /// Doctor dispatches emergency response
  /// Requirements: 3.4
  Future<bool> dispatchSOSCase(String sosId, String doctorId, {String? notes}) async {
    try {
      // Get current SOS status
      final sosSnapshot = await _db.ref('sos_requests/$sosId').get();
      if (!sosSnapshot.exists) {
        print('SOS case not found: $sosId');
        return false;
      }
      
      final sosData = Map<String, dynamic>.from(sosSnapshot.value as Map);
      final currentStatus = sosData['status'] as String? ?? 'pending';
      
      // Validate status transition: only acknowledged can be dispatched
      if (currentStatus != 'acknowledged') {
        print('Invalid status transition: $currentStatus -> dispatched');
        return false;
      }
      
      // Update SOS status
      await _db.ref('sos_requests/$sosId').update({
        'status': 'dispatched',
        'dispatchedAt': DateTime.now().toIso8601String(),
        'dispatchedBy': doctorId,
        'dispatchNotes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Get patient ID for notifications
      final patientId = sosData['userId'] as String?;
      final doctorName = sosData['acknowledgedByName'] as String?;
      
      if (patientId != null) {
        // Notify patient
        await _enhancedNotificationService.sendSOSNotification(
          userId: patientId,
          sosId: sosId,
          status: 'dispatched',
          doctorName: doctorName,
        );
        
        // Notify family members
        await notifyFamilyOnSOSStatusChange(
          userId: patientId,
          sosId: sosId,
          newStatus: 'dispatched',
          doctorName: doctorName,
        );
      }
      
      print('✅ SOS $sosId dispatched');
      return true;
    } catch (e) {
      print('Error dispatching SOS case: $e');
      return false;
    }
  }

  /// Doctor resolves an SOS case and creates medical record
  /// Requirements: 3.5
  Future<bool> resolveSOSCase(String sosId, String doctorId, String resolution, {String? diagnosis}) async {
    try {
      // Get current SOS status
      final sosSnapshot = await _db.ref('sos_requests/$sosId').get();
      if (!sosSnapshot.exists) {
        print('SOS case not found: $sosId');
        return false;
      }
      
      final sosData = Map<String, dynamic>.from(sosSnapshot.value as Map);
      final currentStatus = sosData['status'] as String? ?? 'pending';
      
      // Validate status transition: only acknowledged or dispatched can be resolved
      if (currentStatus != 'acknowledged' && currentStatus != 'dispatched') {
        print('Invalid status transition: $currentStatus -> resolved');
        return false;
      }
      
      // Update SOS status
      await _db.ref('sos_requests/$sosId').update({
        'status': 'resolved',
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolvedBy': doctorId,
        'resolution': resolution,
        'diagnosis': diagnosis,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Get patient ID for notifications and medical record
      final patientId = sosData['userId'] as String?;
      final doctorName = sosData['acknowledgedByName'] as String?;
      
      if (patientId != null) {
        // Create medical record entry for this SOS case
        await _createSOSMedicalRecord(
          patientId: patientId,
          sosId: sosId,
          doctorId: doctorId,
          doctorName: doctorName,
          resolution: resolution,
          diagnosis: diagnosis,
          sosData: sosData,
        );
        
        // Notify patient
        await _enhancedNotificationService.sendSOSNotification(
          userId: patientId,
          sosId: sosId,
          status: 'resolved',
          doctorName: doctorName,
        );
        
        // Notify family members
        await notifyFamilyOnSOSStatusChange(
          userId: patientId,
          sosId: sosId,
          newStatus: 'resolved',
          doctorName: doctorName,
        );
      }
      
      print('✅ SOS $sosId resolved');
      return true;
    } catch (e) {
      print('Error resolving SOS case: $e');
      return false;
    }
  }

  /// Create medical record entry for resolved SOS case
  Future<void> _createSOSMedicalRecord({
    required String patientId,
    required String sosId,
    required String doctorId,
    String? doctorName,
    required String resolution,
    String? diagnosis,
    required Map<String, dynamic> sosData,
  }) async {
    try {
      final recordRef = _db.ref('medical_records/$patientId').push();
      final recordId = recordRef.key!;
      final now = DateTime.now();
      
      await recordRef.set({
        'id': recordId,
        'patientId': patientId,
        'type': 'sos_emergency',
        'sosId': sosId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'diagnosis': diagnosis ?? 'Cấp cứu SOS',
        'resolution': resolution,
        'notes': sosData['notes'],
        'location': sosData['userLocation'],
        'createdAt': now.millisecondsSinceEpoch,
        'sosCreatedAt': sosData['createdAt'],
        'sosResolvedAt': now.toIso8601String(),
      });
      
      print('✅ Medical record created for SOS $sosId');
    } catch (e) {
      print('Error creating SOS medical record: $e');
    }
  }

  /// Get count of active SOS cases (for dashboard)
  Stream<int> getActiveSOSCount() {
    return _db
        .ref('sos_requests')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return 0;
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      int count = 0;
      
      data.forEach((key, value) {
        final sosData = Map<String, dynamic>.from(value as Map);
        final status = sosData['status'] as String? ?? 'pending';
        if (status != 'resolved' && status != 'cancelled') {
          count++;
        }
      });
      
      return count;
    });
  }
}
