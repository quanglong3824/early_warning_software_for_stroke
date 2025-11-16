import 'package:firebase_database/firebase_database.dart';

/// Service quản lý predictions cho Admin
class AdminPredictionService {
  static final AdminPredictionService _instance = AdminPredictionService._internal();
  factory AdminPredictionService() => _instance;
  AdminPredictionService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Lấy tất cả predictions với thông tin user
  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    try {
      print('📊 Admin: Đang lấy tất cả predictions...');
      
      final snapshot = await _database.child('predictions').get();

      if (!snapshot.exists) {
        print('⚠️ Không có predictions nào');
        return [];
      }

      final predictions = <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Lấy thông tin users
      final usersSnapshot = await _database.child('users').get();
      final usersData = usersSnapshot.exists 
          ? Map<String, dynamic>.from(usersSnapshot.value as Map)
          : <String, dynamic>{};

      data.forEach((key, value) {
        final prediction = Map<String, dynamic>.from(value as Map);
        final userId = prediction['userId'] as String?;
        
        // Thêm thông tin user vào prediction
        if (userId != null && usersData.containsKey(userId)) {
          final userData = Map<String, dynamic>.from(usersData[userId] as Map);
          prediction['userName'] = userData['name'] ?? 'N/A';
          prediction['userEmail'] = userData['email'] ?? 'N/A';
        } else {
          prediction['userName'] = 'Unknown User';
          prediction['userEmail'] = 'N/A';
        }
        
        predictions.add(prediction);
      });

      // Sắp xếp theo thời gian mới nhất
      predictions.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      print('✅ Tìm thấy ${predictions.length} predictions');
      return predictions;
    } catch (e) {
      print('❌ Lỗi lấy predictions: $e');
      return [];
    }
  }

  /// Lấy thống kê predictions
  Future<Map<String, dynamic>> getPredictionStats() async {
    try {
      final predictions = await getAllPredictions();

      int totalPredictions = predictions.length;
      int strokePredictions = 0;
      int diabetesPredictions = 0;
      int highRisk = 0;
      int mediumRisk = 0;
      int lowRisk = 0;

      for (var prediction in predictions) {
        final type = prediction['type'] as String?;
        final riskLevel = prediction['riskLevel'] as String?;

        if (type == 'stroke') strokePredictions++;
        if (type == 'diabetes') diabetesPredictions++;

        if (riskLevel == 'high') highRisk++;
        if (riskLevel == 'medium') mediumRisk++;
        if (riskLevel == 'low') lowRisk++;
      }

      return {
        'total': totalPredictions,
        'stroke': strokePredictions,
        'diabetes': diabetesPredictions,
        'highRisk': highRisk,
        'mediumRisk': mediumRisk,
        'lowRisk': lowRisk,
      };
    } catch (e) {
      print('❌ Lỗi lấy thống kê: $e');
      return {
        'total': 0,
        'stroke': 0,
        'diabetes': 0,
        'highRisk': 0,
        'mediumRisk': 0,
        'lowRisk': 0,
      };
    }
  }

  /// Xóa prediction
  Future<bool> deletePrediction(String predictionId) async {
    try {
      await _database.child('predictions').child(predictionId).remove();
      print('✅ Đã xóa prediction: $predictionId');
      return true;
    } catch (e) {
      print('❌ Lỗi xóa prediction: $e');
      return false;
    }
  }

  /// Lấy predictions theo user
  Future<List<Map<String, dynamic>>> getPredictionsByUser(String userId) async {
    try {
      final allPredictions = await getAllPredictions();
      return allPredictions.where((p) => p['userId'] == userId).toList();
    } catch (e) {
      print('❌ Lỗi lấy predictions theo user: $e');
      return [];
    }
  }
}
