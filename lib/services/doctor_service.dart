import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/doctor_models.dart';

class DoctorService {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;
  DoctorService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get all doctors
  Stream<List<DoctorModel>> getAllDoctors() {
    return _db.child('users').onValue.map((event) {
      final List<DoctorModel> doctors = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final userData = Map<String, dynamic>.from(value as Map);
          // Only include users with role='doctor'
          if (userData['role'] == 'doctor') {
            try {
              doctors.add(DoctorModel.fromJson(userData));
            } catch (e) {
              print('Error parsing doctor $key: $e');
            }
          }
        });
      }
      return doctors;
    });
  }

  /// Get verified doctors only
  Stream<List<DoctorModel>> getVerifiedDoctors() {
    return getAllDoctors().map((doctors) {
      return doctors.where((d) => d.isVerified).toList();
    });
  }

  /// Get available doctors
  Stream<List<DoctorModel>> getAvailableDoctors() {
    return getAllDoctors().map((doctors) {
      return doctors.where((d) => d.isAvailable && d.isVerified).toList();
    });
  }

  /// Get doctor by ID
  Future<DoctorModel?> getDoctor(String doctorId) async {
    try {
      final snapshot = await _db.child('users').child(doctorId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        // Verify it's a doctor
        if (data['role'] == 'doctor') {
          return DoctorModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting doctor: $e');
      return null;
    }
  }

  /// Get doctor stats
  Future<DoctorStatsModel?> getDoctorStats(String doctorId) async {
    try {
      final snapshot = await _db.child('doctor_stats').child(doctorId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return DoctorStatsModel.fromJson(data);
      }
      // Return default stats if not exists
      return DoctorStatsModel(
        doctorId: doctorId,
        totalPatients: 0,
        totalAppointments: 0,
        completedAppointments: 0,
        cancelledAppointments: 0,
        totalConsultations: 0,
        totalPrescriptions: 0,
        averageRating: 0.0,
        totalReviews: 0,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error getting doctor stats: $e');
      return null;
    }
  }

  /// Update doctor availability
  Future<bool> updateAvailability(String doctorId, bool isAvailable) async {
    try {
      await _db.child('doctors').child(doctorId).update({
        'isAvailable': isAvailable,
      });
      return true;
    } catch (e) {
      print('Error updating availability: $e');
      return false;
    }
  }

  /// Update doctor profile
  Future<bool> updateDoctorProfile({
    required String doctorId,
    String? name,
    String? phone,
    String? specialization,
    String? hospital,
    String? department,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (specialization != null) updates['specialization'] = specialization;
      if (hospital != null) updates['hospital'] = hospital;
      if (department != null) updates['department'] = department;
      if (bio != null) updates['bio'] = bio;

      await _db.child('doctors').child(doctorId).update(updates);
      return true;
    } catch (e) {
      print('Error updating doctor profile: $e');
      return false;
    }
  }

  /// Increment appointment count
  Future<void> incrementAppointmentCount(String doctorId) async {
    try {
      await _db.child('doctor_stats').child(doctorId).update({
        'totalAppointments': ServerValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error incrementing appointment count: $e');
    }
  }

  /// Increment completed appointment count
  Future<void> incrementCompletedAppointment(String doctorId) async {
    try {
      await _db.child('doctor_stats').child(doctorId).update({
        'completedAppointments': ServerValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error incrementing completed appointment: $e');
    }
  }

  /// Increment prescription count
  Future<void> incrementPrescriptionCount(String doctorId) async {
    try {
      await _db.child('doctor_stats').child(doctorId).update({
        'totalPrescriptions': ServerValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error incrementing prescription count: $e');
    }
  }

  /// Search doctors by name or specialization
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final snapshot = await _db.child('users').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final doctors = <DoctorModel>[];
      
      data.forEach((key, value) {
        final userData = Map<String, dynamic>.from(value as Map);
        // Only include doctors
        if (userData['role'] == 'doctor') {
          try {
            final doctor = DoctorModel.fromJson(userData);
            
            final lowerQuery = query.toLowerCase();
            if (doctor.name.toLowerCase().contains(lowerQuery) ||
                (doctor.specialization?.toLowerCase().contains(lowerQuery) ?? false) ||
                (doctor.hospital?.toLowerCase().contains(lowerQuery) ?? false)) {
              doctors.add(doctor);
            }
          } catch (e) {
            print('Error parsing doctor $key: $e');
          }
        }
      });

      return doctors;
    } catch (e) {
      print('Error searching doctors: $e');
      return [];
    }
  }
  /// Submit doctor review
  Future<bool> submitReview({
    required String doctorId,
    required String userId,
    required double rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    try {
      final reviewRef = _db.child('doctor_reviews').child(doctorId).push();
      
      await reviewRef.set({
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'isAnonymous': isAnonymous,
        'createdAt': ServerValue.timestamp,
      });

      // Update doctor stats
      await _db.child('doctor_stats').child(doctorId).runTransaction((Object? post) {
        if (post == null) {
          return Transaction.success({
            'totalReviews': 1,
            'averageRating': rating,
            'updatedAt': ServerValue.timestamp,
          });
        }
        
        final Map<String, dynamic> data = Map<String, dynamic>.from(post as Map);
        final int totalReviews = (data['totalReviews'] ?? 0) + 1;
        final double currentRating = (data['averageRating'] ?? 0).toDouble();
        final double newRating = ((currentRating * (totalReviews - 1)) + rating) / totalReviews;
        
        data['totalReviews'] = totalReviews;
        data['averageRating'] = newRating;
        data['updatedAt'] = ServerValue.timestamp;
        
        return Transaction.success(data);
      });

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }
}
