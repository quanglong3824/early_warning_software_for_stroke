import 'package:flutter_test/flutter_test.dart';
import 'firebase_service.dart';

/// Unit tests cho FirebaseService
/// Run: flutter test test/backend/firebase_service_test.dart
void main() {
  group('FirebaseService Tests', () {
    late FirebaseService service;

    setUp(() {
      service = FirebaseService();
    });

    test('Service should be singleton', () {
      final service1 = FirebaseService();
      final service2 = FirebaseService();
      expect(service1, equals(service2));
    });

    group('Patient Operations', () {
      test('Get patients should return list', () async {
        final patients = await service.getPatients();
        expect(patients, isA<List<Map<String, dynamic>>>());
      });

      test('Get patient by ID should return patient or null', () async {
        final patient = await service.getPatientById('patient_001');
        expect(patient, anyOf(isNull, isA<Map<String, dynamic>>()));
      });

      test('Add patient should return bool', () async {
        final testPatient = {
          'id': 'test_patient_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Test Patient',
          'status': 'stable',
          'mainValue': '120/80',
          'unit': 'mmHg',
          'lastUpdate': DateTime.now().toIso8601String(),
        };
        
        final result = await service.addPatient(testPatient);
        expect(result, isA<bool>());
      });

      test('Update patient should return bool', () async {
        final result = await service.updatePatient('patient_001', {
          'status': 'stable',
        });
        expect(result, isA<bool>());
      });
    });

    group('Alert Operations', () {
      test('Get alerts should return list', () async {
        final alerts = await service.getAlerts();
        expect(alerts, isA<List<Map<String, dynamic>>>());
      });

      test('Get unread alerts should return list', () async {
        final alerts = await service.getAlerts(isRead: false);
        expect(alerts, isA<List<Map<String, dynamic>>>());
      });

      test('Mark alert as read should return bool', () async {
        final result = await service.markAlertAsRead('alert_001');
        expect(result, isA<bool>());
      });
    });

    group('Forum Operations', () {
      test('Get forum posts should return list', () async {
        final posts = await service.getForumPosts();
        expect(posts, isA<List<Map<String, dynamic>>>());
      });

      test('Get limited forum posts should return list', () async {
        final posts = await service.getForumPosts(limit: 5);
        expect(posts, isA<List<Map<String, dynamic>>>());
        expect(posts.length, lessThanOrEqualTo(5));
      });

      test('Add forum post should return bool', () async {
        final testPost = {
          'id': 'test_post_${DateTime.now().millisecondsSinceEpoch}',
          'authorId': 'user_001',
          'authorName': 'Test User',
          'title': 'Test Post',
          'content': 'This is a test post',
          'likes': 0,
          'comments': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'tags': ['test'],
        };
        
        final result = await service.addForumPost(testPost);
        expect(result, isA<bool>());
      });
    });

    group('Knowledge Operations', () {
      test('Get knowledge articles should return list', () async {
        final articles = await service.getKnowledgeArticles();
        expect(articles, isA<List<Map<String, dynamic>>>());
      });

      test('Get articles by category should return list', () async {
        final articles = await service.getKnowledgeArticles(
          category: 'Sức khỏe Tim mạch',
        );
        expect(articles, isA<List<Map<String, dynamic>>>());
      });

      test('Get limited articles should return list', () async {
        final articles = await service.getKnowledgeArticles(limit: 10);
        expect(articles, isA<List<Map<String, dynamic>>>());
        expect(articles.length, lessThanOrEqualTo(10));
      });
    });

    group('Doctor Operations', () {
      test('Get doctor appointments should return list', () async {
        final appointments = await service.getDoctorAppointments('doctor_001');
        expect(appointments, isA<List<Map<String, dynamic>>>());
      });

      test('Get active SOS should return list', () async {
        final sosCalls = await service.getActiveSOS();
        expect(sosCalls, isA<List<Map<String, dynamic>>>());
      });

      test('Update SOS status should return bool', () async {
        final result = await service.updateSOSStatus('sos_001', 'resolved');
        expect(result, isA<bool>());
      });

      test('Add prescription should return bool', () async {
        final testPrescription = {
          'id': 'test_pres_${DateTime.now().millisecondsSinceEpoch}',
          'patientId': 'patient_001',
          'patientName': 'Test Patient',
          'date': DateTime.now().toIso8601String(),
          'medications': [],
          'diagnosis': 'Test diagnosis',
          'notes': 'Test notes',
        };
        
        final result = await service.addPrescription(testPrescription);
        expect(result, isA<bool>());
      });

      test('Get patient prescriptions should return list', () async {
        final prescriptions = await service.getPatientPrescriptions('patient_001');
        expect(prescriptions, isA<List<Map<String, dynamic>>>());
      });

      test('Get doctor reviews should return list', () async {
        final reviews = await service.getDoctorReviews('doctor_001');
        expect(reviews, isA<List<Map<String, dynamic>>>());
      });
    });

    group('Utility Operations', () {
      test('Test connection should return bool', () async {
        final result = await service.testConnection();
        expect(result, isA<bool>());
      });

      test('Get collection count should return int', () async {
        final count = await service.getCollectionCount('user_patients');
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });

      test('Batch insert should return bool', () async {
        final testData = [
          {
            'id': 'batch_test_1',
            'name': 'Batch Test 1',
          },
          {
            'id': 'batch_test_2',
            'name': 'Batch Test 2',
          },
        ];
        
        final result = await service.batchInsert('test_collection', testData);
        expect(result, isA<bool>());
      });

      test('Listen to collection should return stream', () {
        final stream = service.listenToCollection('user_patients');
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      });
    });
  });
}
