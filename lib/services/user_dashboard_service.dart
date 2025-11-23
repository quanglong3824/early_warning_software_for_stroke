import 'package:firebase_database/firebase_database.dart';

/// Service lấy dữ liệu dashboard cho user
class UserDashboardService {
  static final UserDashboardService _instance = UserDashboardService._internal();
  factory UserDashboardService() => _instance;
  UserDashboardService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Lấy thống kê dashboard
  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    try {
      // Lấy predictions của user
      final predictionsSnapshot = await _database.child('predictions').get();
      
      int totalPredictions = 0;
      int highRiskCount = 0;
      int mediumRiskCount = 0;
      int lowRiskCount = 0;
      int strokeCount = 0;
      int diabetesCount = 0;
      
      Map<String, dynamic>? latestPrediction;
      Map<String, dynamic>? latestStrokePrediction;
      Map<String, dynamic>? latestDiabetesPrediction;
      int latestTime = 0;
      int latestStrokeTime = 0;
      int latestDiabetesTime = 0;

      if (predictionsSnapshot.exists) {
        final data = Map<String, dynamic>.from(predictionsSnapshot.value as Map);
        
        data.forEach((key, value) {
          final prediction = Map<String, dynamic>.from(value as Map);
          final predUserId = prediction['userId'] as String?;
          
          if (predUserId == userId) {
            totalPredictions++;
            
            final riskLevel = prediction['riskLevel'] as String?;
            if (riskLevel == 'high') highRiskCount++;
            if (riskLevel == 'medium') mediumRiskCount++;
            if (riskLevel == 'low') lowRiskCount++;
            
            final type = prediction['type'] as String?;
            final createdAt = prediction['createdAt'] as int? ?? 0;
            
            if (type == 'stroke') {
              strokeCount++;
              if (createdAt > latestStrokeTime) {
                latestStrokeTime = createdAt;
                latestStrokePrediction = prediction;
              }
            }
            
            if (type == 'diabetes') {
              diabetesCount++;
              if (createdAt > latestDiabetesTime) {
                latestDiabetesTime = createdAt;
                latestDiabetesPrediction = prediction;
              }
            }
            
            // Tìm prediction mới nhất (tổng thể)
            if (createdAt > latestTime) {
              latestTime = createdAt;
              latestPrediction = prediction;
            }
          }
        });
      }

      // Lấy số lượng gia đình
      int familyMembersCount = 0;
      final familySnapshot = await _database
          .child('family_members')
          .child(userId)
          .get();
      
      if (familySnapshot.exists) {
        final familyData = Map<String, dynamic>.from(familySnapshot.value as Map);
        familyMembersCount = familyData.length;
      }

      // Lấy số lượng appointments
      int upcomingAppointments = 0;
      final appointmentsSnapshot = await _database.child('appointments').get();
      
      if (appointmentsSnapshot.exists) {
        final data = Map<String, dynamic>.from(appointmentsSnapshot.value as Map);
        final now = DateTime.now().millisecondsSinceEpoch;
        
        data.forEach((key, value) {
          final appointment = Map<String, dynamic>.from(value as Map);
          final apptUserId = appointment['userId'] as String?;
          final status = appointment['status'] as String?;
          final appointmentTime = appointment['appointmentTime'] as int? ?? 0;
          
          if (apptUserId == userId && 
              status == 'confirmed' && 
              appointmentTime > now) {
            upcomingAppointments++;
          }
        });
      }

      return {
        'totalPredictions': totalPredictions,
        'highRiskCount': highRiskCount,
        'mediumRiskCount': mediumRiskCount,
        'lowRiskCount': lowRiskCount,
        'strokeCount': strokeCount,
        'diabetesCount': diabetesCount,
        'familyMembersCount': familyMembersCount,
        'upcomingAppointments': upcomingAppointments,
        'latestPrediction': latestPrediction,
        'latestStrokePrediction': latestStrokePrediction,
        'latestDiabetesPrediction': latestDiabetesPrediction,
      };
    } catch (e) {
      print('❌ Lỗi lấy dashboard stats: $e');
      return {
        'totalPredictions': 0,
        'highRiskCount': 0,
        'mediumRiskCount': 0,
        'lowRiskCount': 0,
        'strokeCount': 0,
        'diabetesCount': 0,
        'familyMembersCount': 0,
        'upcomingAppointments': 0,
        'latestPrediction': null,
        'latestStrokePrediction': null,
        'latestDiabetesPrediction': null,
      };
    }
  }

  /// Lấy danh sách gia đình
  Future<List<Map<String, dynamic>>> getFamilyMembers(String userId) async {
    try {
      final snapshot = await _database
          .child('family_members')
          .child(userId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final members = <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Lấy thông tin chi tiết của từng member
      for (var entry in data.entries) {
        final memberData = Map<String, dynamic>.from(entry.value as Map);
        final memberId = memberData['memberId'] as String?;
        
        if (memberId != null) {
          final userSnapshot = await _database.child('users').child(memberId).get();
          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            members.add({
              'id': memberId,
              'name': userData['name'] ?? 'Unknown',
              'email': userData['email'] ?? '',
              'relationship': memberData['relationship'] ?? 'Member',
              'addedAt': memberData['addedAt'],
            });
          }
        }
      }

      return members;
    } catch (e) {
      print('❌ Lỗi lấy family members: $e');
      return [];
    }
  }

  /// Lấy appointments sắp tới
  Future<List<Map<String, dynamic>>> getUpcomingAppointments(String userId) async {
    try {
      final snapshot = await _database.child('appointments').get();

      if (!snapshot.exists) {
        return [];
      }

      final appointments = <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var entry in data.entries) {
        final appointment = Map<String, dynamic>.from(entry.value as Map);
        final apptUserId = appointment['userId'] as String?;
        final status = appointment['status'] as String?;
        final appointmentTime = appointment['appointmentTime'] as int? ?? 0;

        if (apptUserId == userId && 
            status == 'confirmed' && 
            appointmentTime > now) {
          
          // Fetch doctor name
          final doctorId = appointment['doctorId'] as String?;
          String doctorName = 'Bác sĩ';
          
          if (doctorId != null) {
            try {
              final doctorSnapshot = await _database.child('users').child(doctorId).get();
              if (doctorSnapshot.exists) {
                final doctorData = Map<String, dynamic>.from(doctorSnapshot.value as Map);
                doctorName = doctorData['name'] as String? ?? 'Bác sĩ';
              }
            } catch (e) {
              print('Error fetching doctor name: $e');
            }
          }
          
          appointments.add({
            ...appointment,
            'doctorName': doctorName,
          });
        }
      }

      // Sắp xếp theo thời gian
      appointments.sort((a, b) {
        final aTime = a['appointmentTime'] as int? ?? 0;
        final bTime = b['appointmentTime'] as int? ?? 0;
        return aTime.compareTo(bTime);
      });

      return appointments;
    } catch (e) {
      print('❌ Lỗi lấy appointments: $e');
      return [];
    }
  }
}
