import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class SOSService {
  final _db = FirebaseDatabase.instance;
  final _locationService = LocationService();
  final _notificationService = NotificationService();
  final _authService = AuthService();

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

  /// Update SOS status
  Future<void> updateSOSStatus(String sosId, String status) async {
    try {
      await _db.ref('sos_requests/$sosId').update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
        if (status == 'acknowledged') 'acknowledgedAt': DateTime.now().toIso8601String(),
        if (status == 'dispatched') 'dispatchedAt': DateTime.now().toIso8601String(),
        if (status == 'resolved') 'resolvedAt': DateTime.now().toIso8601String(),
      });
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

  /// Notify family members
  Future<void> _notifyFamilyMembers(String userId, String sosId, String address) async {
    try {
      // Get family members
      final familySnapshot = await _db.ref('family_members/$userId').get();
      
      if (familySnapshot.exists) {
        final familyData = Map<String, dynamic>.from(familySnapshot.value as Map);
        
        for (var entry in familyData.entries) {
          final member = Map<String, dynamic>.from(entry.value as Map);
          final memberId = member['memberId'] as String;
          
          // Create notification
          await _db.ref('notifications/$memberId').push().set({
            'type': 'sos_alert',
            'title': '🚨 Cảnh báo SOS',
            'message': 'Người thân của bạn đã gửi tín hiệu SOS tại $address',
            'data': {
              'sosId': sosId,
              'userId': userId,
            },
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error notifying family: $e');
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
}
