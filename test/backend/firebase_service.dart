import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

/// Firebase Realtime Database Backend Service
/// Tách riêng để dễ test và maintain
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // ===== USERS =====
  
  /// Get all patients
  Future<List<Map<String, dynamic>>> getPatients() async {
    try {
      final snapshot = await _database.child('user_patients').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('Error getting patients: $e');
      return [];
    }
  }

  /// Get patient by ID
  Future<Map<String, dynamic>?> getPatientById(String id) async {
    try {
      final snapshot = await _database.child('user_patients').child(id).get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }

  /// Add new patient
  Future<bool> addPatient(Map<String, dynamic> patientData) async {
    try {
      await _database
          .child('user_patients')
          .child(patientData['id'])
          .set(patientData);
      return true;
    } catch (e) {
      print('Error adding patient: $e');
      return false;
    }
  }

  /// Update patient
  Future<bool> updatePatient(String id, Map<String, dynamic> updates) async {
    try {
      await _database.child('user_patients').child(id).update(updates);
      return true;
    } catch (e) {
      print('Error updating patient: $e');
      return false;
    }
  }

  // ===== ALERTS =====
  
  /// Get all alerts
  Future<List<Map<String, dynamic>>> getAlerts({bool? isRead}) async {
    try {
      final snapshot = await _database.child('user_alerts').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var alerts = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      if (isRead != null) {
        alerts = alerts.where((alert) => alert['isRead'] == isRead).toList();
      }
      
      return alerts;
    } catch (e) {
      print('Error getting alerts: $e');
      return [];
    }
  }

  /// Mark alert as read
  Future<bool> markAlertAsRead(String alertId) async {
    try {
      await _database.child('user_alerts').child(alertId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      print('Error marking alert as read: $e');
      return false;
    }
  }

  // ===== FORUM =====
  
  /// Get forum posts
  Future<List<Map<String, dynamic>>> getForumPosts({int? limit}) async {
    try {
      final snapshot = await _database.child('user_forumPosts').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var posts = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Sort by createdAt
      posts.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      if (limit != null && posts.length > limit) {
        posts = posts.sublist(0, limit);
      }
      
      return posts;
    } catch (e) {
      print('Error getting forum posts: $e');
      return [];
    }
  }

  /// Add forum post
  Future<bool> addForumPost(Map<String, dynamic> postData) async {
    try {
      await _database
          .child('user_forumPosts')
          .child(postData['id'])
          .set(postData);
      return true;
    } catch (e) {
      print('Error adding forum post: $e');
      return false;
    }
  }

  // ===== KNOWLEDGE =====
  
  /// Get knowledge articles
  Future<List<Map<String, dynamic>>> getKnowledgeArticles({
    String? category,
    int? limit,
  }) async {
    try {
      final snapshot = await _database.child('user_knowledgeArticles').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var articles = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Filter by category
      if (category != null && category != 'Tất cả') {
        articles = articles.where((article) {
          final categories = article['categories'] as List?;
          return categories?.contains(category) ?? false;
        }).toList();
      }
      
      // Sort by publishedAt
      articles.sort((a, b) {
        final aTime = a['publishedAt'] ?? 0;
        final bTime = b['publishedAt'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      if (limit != null && articles.length > limit) {
        articles = articles.sublist(0, limit);
      }
      
      return articles;
    } catch (e) {
      print('Error getting knowledge articles: $e');
      return [];
    }
  }

  // ===== DOCTOR =====
  
  /// Get doctor's appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) async {
    try {
      final snapshot = await _database.child('doctor_todayAppointments').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var appointments = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Filter by doctorId
      appointments = appointments.where((apt) => apt['doctorId'] == doctorId).toList();
      
      return appointments;
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  /// Get active SOS calls
  Future<List<Map<String, dynamic>>> getActiveSOS() async {
    try {
      final snapshot = await _database.child('doctor_activeSOS').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var sosCalls = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Filter by status
      sosCalls = sosCalls.where((sos) => sos['status'] == 'active').toList();
      
      // Sort by createdAt
      sosCalls.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return sosCalls;
    } catch (e) {
      print('Error getting SOS calls: $e');
      return [];
    }
  }

  /// Update SOS status
  Future<bool> updateSOSStatus(String sosId, String status) async {
    try {
      await _database.child('doctor_activeSOS').child(sosId).update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print('Error updating SOS status: $e');
      return false;
    }
  }

  // ===== PRESCRIPTIONS =====
  
  /// Add prescription
  Future<bool> addPrescription(Map<String, dynamic> prescriptionData) async {
    try {
      await _database
          .child('doctor_prescriptions')
          .child(prescriptionData['id'])
          .set(prescriptionData);
      return true;
    } catch (e) {
      print('Error adding prescription: $e');
      return false;
    }
  }

  /// Get patient prescriptions
  Future<List<Map<String, dynamic>>> getPatientPrescriptions(String patientId) async {
    try {
      final snapshot = await _database.child('doctor_prescriptions').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var prescriptions = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Filter by patientId
      prescriptions = prescriptions.where((p) => p['patientId'] == patientId).toList();
      
      // Sort by date
      prescriptions.sort((a, b) {
        final aDate = a['date'] ?? 0;
        final bDate = b['date'] ?? 0;
        return bDate.compareTo(aDate);
      });
      
      return prescriptions;
    } catch (e) {
      print('Error getting prescriptions: $e');
      return [];
    }
  }

  // ===== REVIEWS =====
  
  /// Get doctor reviews
  Future<List<Map<String, dynamic>>> getDoctorReviews(String doctorId) async {
    try {
      final snapshot = await _database.child('doctor_doctorReviews').get();
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      var reviews = data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Filter by doctorId
      reviews = reviews.where((r) => r['doctorId'] == doctorId).toList();
      
      // Sort by createdAt
      reviews.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return reviews;
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  // ===== UTILITY =====
  
  /// Test connection
  Future<bool> testConnection() async {
    try {
      await _database.child('test').child('connection').set({
        'timestamp': ServerValue.timestamp,
        'status': 'connected',
      });
      return true;
    } catch (e) {
      print('Error testing connection: $e');
      return false;
    }
  }

  /// Batch insert data
  Future<bool> batchInsert(
    String collection,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final updates = <String, dynamic>{};
      
      for (var item in data) {
        if (item.containsKey('id')) {
          updates['$collection/${item['id']}'] = item;
        }
      }
      
      await _database.update(updates);
      return true;
    } catch (e) {
      print('Error batch insert: $e');
      return false;
    }
  }

  /// Clear collection
  Future<bool> clearCollection(String collection) async {
    try {
      await _database.child(collection).remove();
      return true;
    } catch (e) {
      print('Error clearing collection: $e');
      return false;
    }
  }

  /// Get collection count
  Future<int> getCollectionCount(String collection) async {
    try {
      final snapshot = await _database.child(collection).get();
      if (!snapshot.exists) return 0;
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.keys.length;
    } catch (e) {
      print('Error getting collection count: $e');
      return 0;
    }
  }

  /// Listen to real-time updates
  Stream<List<Map<String, dynamic>>> listenToCollection(String collection) {
    return _database.child(collection).onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }
}
