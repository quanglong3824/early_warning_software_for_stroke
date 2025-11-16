import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

/// Service xử lý dự đoán nguy cơ tiểu đường type 2
class DiabetesPredictionService {
  static final DiabetesPredictionService _instance = DiabetesPredictionService._internal();
  factory DiabetesPredictionService() => _instance;
  DiabetesPredictionService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Tính toán BMI
  double calculateBMI(double heightCm, double weightKg) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Dự đoán nguy cơ tiểu đường (thuật toán đơn giản dựa trên các yếu tố nguy cơ)
  /// Trả về Map với riskScore (0-100) và riskLevel (low/medium/high)
  Map<String, dynamic> predictDiabetesRisk({
    required int age,
    required String gender, // 'male' hoặc 'female'
    required double heightCm,
    required double weightKg,
    required double fastingGlucose, // mg/dL
    required double systolicBP, // mmHg
    required bool familyHistory,
    required String activityLevel, // 'low', 'moderate', 'high'
  }) {
    double riskScore = 0.0;

    // 1. Tuổi (0-20 điểm)
    if (age >= 45) {
      riskScore += 20;
    } else if (age >= 35) {
      riskScore += 10;
    } else if (age >= 25) {
      riskScore += 5;
    }

    // 2. BMI (0-25 điểm)
    final bmi = calculateBMI(heightCm, weightKg);
    if (bmi >= 30) {
      riskScore += 25; // Béo phì
    } else if (bmi >= 25) {
      riskScore += 15; // Thừa cân
    } else if (bmi >= 23) {
      riskScore += 8; // Ngưỡng châu Á
    }

    // 3. Đường huyết lúc đói (0-30 điểm)
    if (fastingGlucose >= 126) {
      riskScore += 30; // Ngưỡng tiểu đường
    } else if (fastingGlucose >= 100) {
      riskScore += 20; // Tiền tiểu đường
    } else if (fastingGlucose >= 90) {
      riskScore += 10;
    }

    // 4. Huyết áp (0-10 điểm)
    if (systolicBP >= 140) {
      riskScore += 10;
    } else if (systolicBP >= 130) {
      riskScore += 5;
    }

    // 5. Tiền sử gia đình (0-10 điểm)
    if (familyHistory) {
      riskScore += 10;
    }

    // 6. Mức độ hoạt động (0-5 điểm)
    if (activityLevel == 'low') {
      riskScore += 5;
    } else if (activityLevel == 'moderate') {
      riskScore += 2;
    }

    // Chuẩn hóa điểm về thang 0-100
    riskScore = min(100, riskScore);

    // Xác định mức độ nguy cơ
    String riskLevel;
    String riskLevelVi;
    if (riskScore >= 60) {
      riskLevel = 'high';
      riskLevelVi = 'Nguy cơ cao';
    } else if (riskScore >= 30) {
      riskLevel = 'medium';
      riskLevelVi = 'Nguy cơ trung bình';
    } else {
      riskLevel = 'low';
      riskLevelVi = 'Nguy cơ thấp';
    }

    return {
      'riskScore': riskScore.round(),
      'riskLevel': riskLevel,
      'riskLevelVi': riskLevelVi,
      'bmi': bmi.toStringAsFixed(1),
      'bmiCategory': _getBMICategory(bmi),
    };
  }

  /// Phân loại BMI
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Thừa cân nhẹ';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Lưu kết quả dự đoán vào Firebase
  Future<Map<String, dynamic>> savePredictionResult({
    required String userId,
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> predictionResult,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final predictionId = 'diabetes_$userId\_$timestamp';

      final data = {
        'id': predictionId,
        'userId': userId,
        'type': 'diabetes',
        'riskScore': predictionResult['riskScore'],
        'riskLevel': predictionResult['riskLevel'],
        'riskLevelVi': predictionResult['riskLevelVi'],
        'bmi': predictionResult['bmi'],
        'bmiCategory': predictionResult['bmiCategory'],
        'inputData': inputData,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };

      // Lưu vào predictions/{predictionId}
      await _database.child('predictions').child(predictionId).set(data);

      // Lưu reference vào user predictions
      await _database
          .child('users')
          .child(userId)
          .child('predictions')
          .child(predictionId)
          .set({
        'type': 'diabetes',
        'riskLevel': predictionResult['riskLevel'],
        'createdAt': ServerValue.timestamp,
      });

      print('✅ Đã lưu kết quả dự đoán tiểu đường: $predictionId');

      return {
        'success': true,
        'message': 'Đã lưu kết quả dự đoán',
        'predictionId': predictionId,
      };
    } catch (e) {
      print('❌ Lỗi lưu kết quả dự đoán: $e');
      return {
        'success': false,
        'message': 'Lỗi lưu kết quả: $e',
      };
    }
  }

  /// Lấy lịch sử dự đoán của user
  Future<List<Map<String, dynamic>>> getUserPredictions(String userId) async {
    try {
      print('🔍 Đang tìm dự đoán tiểu đường cho userId: $userId');
      
      // Lấy tất cả predictions
      final snapshot = await _database.child('predictions').get();

      print('📊 Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        print('⚠️ Không tìm thấy dữ liệu predictions');
        return [];
      }

      final predictions = <Map<String, dynamic>>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      print('📦 Tổng số predictions trong DB: ${data.length}');

      // Filter theo userId và type
      data.forEach((key, value) {
        final prediction = Map<String, dynamic>.from(value as Map);
        final predUserId = prediction['userId'] as String?;
        final predType = prediction['type'] as String?;
        
        print('🔎 Checking prediction: userId=$predUserId, type=$predType');
        
        if (predUserId == userId && predType == 'diabetes') {
          predictions.add(prediction);
        }
      });

      print('✅ Tìm thấy ${predictions.length} dự đoán tiểu đường cho user $userId');

      // Sắp xếp theo thời gian mới nhất
      predictions.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return predictions;
    } catch (e) {
      print('❌ Lỗi lấy lịch sử dự đoán: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Lấy kết quả dự đoán mới nhất
  Future<Map<String, dynamic>?> getLatestPrediction(String userId) async {
    try {
      final predictions = await getUserPredictions(userId);
      return predictions.isNotEmpty ? predictions.first : null;
    } catch (e) {
      print('❌ Lỗi lấy kết quả mới nhất: $e');
      return null;
    }
  }

  /// Lấy khuyến nghị dựa trên mức độ nguy cơ
  Map<String, List<String>> getRecommendations(String riskLevel) {
    if (riskLevel == 'high') {
      return {
        'nutrition': [
          'Cắt giảm đồ uống có đường và thực phẩm chế biến sẵn.',
          'Tăng cường ăn rau xanh, trái cây và ngũ cốc nguyên hạt.',
          'Uống đủ 2 lít nước mỗi ngày.',
          'Hạn chế tinh bột trắng, chuyển sang gạo lứt, bánh mì nguyên cám.',
        ],
        'exercise': [
          'Tập thể dục ít nhất 150 phút mỗi tuần với cường độ vừa phải.',
          'Kết hợp các bài tập cardio (đi bộ, chạy) và sức mạnh.',
          'Hạn chế ngồi một chỗ quá lâu, đứng dậy đi lại sau mỗi 30 phút.',
        ],
        'monitoring': [
          'Thường xuyên kiểm tra đường huyết theo chỉ dẫn của bác sĩ.',
          'Thực hiện các xét nghiệm định kỳ để theo dõi tình trạng sức khỏe.',
          'Tham khảo ý kiến bác sĩ chuyên khoa để được tư vấn cụ thể.',
          'Cân nhắc tham gia các chương trình quản lý tiểu đường.',
        ],
      };
    } else if (riskLevel == 'medium') {
      return {
        'nutrition': [
          'Giảm lượng đường và tinh bột tinh chế trong chế độ ăn.',
          'Tăng cường rau xanh và protein nạc.',
          'Ăn nhiều bữa nhỏ trong ngày thay vì ít bữa lớn.',
        ],
        'exercise': [
          'Tập thể dục ít nhất 30 phút mỗi ngày.',
          'Đi bộ sau bữa ăn để kiểm soát đường huyết.',
          'Tham gia các hoạt động thể thao nhóm để duy trì động lực.',
        ],
        'monitoring': [
          'Kiểm tra đường huyết định kỳ 3-6 tháng/lần.',
          'Theo dõi cân nặng và BMI thường xuyên.',
          'Tham khảo bác sĩ nếu có triệu chứng bất thường.',
        ],
      };
    } else {
      return {
        'nutrition': [
          'Duy trì chế độ ăn cân bằng và đa dạng.',
          'Hạn chế đồ ngọt và thức ăn nhanh.',
          'Uống đủ nước mỗi ngày.',
        ],
        'exercise': [
          'Duy trì hoạt động thể chất đều đặn.',
          'Tìm các hoạt động vận động yêu thích để duy trì lâu dài.',
        ],
        'monitoring': [
          'Kiểm tra sức khỏe định kỳ hàng năm.',
          'Duy trì lối sống lành mạnh để phòng ngừa bệnh tật.',
        ],
      };
    }
  }
}
