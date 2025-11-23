import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'ai_stroke_prediction_service.dart';

/// Service xử lý dự đoán nguy cơ đột quỵ
class StrokePredictionService {
  static final StrokePredictionService _instance = StrokePredictionService._internal();
  factory StrokePredictionService() => _instance;
  StrokePredictionService._internal() {
    _checkAPIHealth();
  }

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AIStrokePredictionService _aiService = AIStrokePredictionService();
  bool _useAI = false;

  /// Check if Flask API is available
  Future<void> _checkAPIHealth() async {
    _useAI = await _aiService.checkHealth();
    if (_useAI) {
      print('✅ Flask API is available - using AI predictions');
    } else {
      print('⚠️ Flask API unavailable - using rule-based predictions');
    }
  }

  /// Tính toán BMI
  double calculateBMI(double heightCm, double weightKg) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Dự đoán nguy cơ đột quỵ (AI hoặc rule-based)
  Future<Map<String, dynamic>> predictStrokeRisk({
    required int age,
    required String gender, // 'male' hoặc 'female'
    required double heightCm,
    required double weightKg,
    required double systolicBP, // mmHg
    required double diastolicBP, // mmHg
    required double cholesterol, // mg/dL
    required double glucose, // mg/dL
    required bool hypertension,
    required bool heartDisease,
    required bool smoking,
    required String workType, // 'sedentary', 'moderate', 'active'
  }) async {
    // Try AI prediction first
    if (_useAI) {
      try {
        final aiResult = await _aiService.predictStrokeRisk(
          age: age,
          gender: gender,
          heightCm: heightCm,
          weightKg: weightKg,
          systolicBP: systolicBP,
          diastolicBP: diastolicBP,
          cholesterol: cholesterol,
          glucose: glucose,
          hypertension: hypertension,
          heartDisease: heartDisease,
          smoking: smoking,
          workType: workType,
        );

        if (aiResult != null) {
          print('🤖 Using AI prediction');
          return aiResult;
        }
      } catch (e) {
        print('⚠️ AI prediction failed, falling back to rule-based: $e');
      }
    }

    // Fallback to rule-based prediction
    print('📊 Using rule-based prediction');
    return _ruleBasedPrediction(
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      cholesterol: cholesterol,
      glucose: glucose,
      hypertension: hypertension,
      heartDisease: heartDisease,
      smoking: smoking,
      workType: workType,
    );
  }

  /// Rule-based prediction (original logic)
  Map<String, dynamic> _ruleBasedPrediction({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double systolicBP,
    required double diastolicBP,
    required double cholesterol,
    required double glucose,
    required bool hypertension,
    required bool heartDisease,
    required bool smoking,
    required String workType,
  }) {
    double riskScore = 0.0;

    // 1. Tuổi (0-25 điểm)
    if (age >= 75) {
      riskScore += 25;
    } else if (age >= 65) {
      riskScore += 20;
    } else if (age >= 55) {
      riskScore += 15;
    } else if (age >= 45) {
      riskScore += 10;
    } else if (age >= 35) {
      riskScore += 5;
    }

    // 2. Giới tính (0-3 điểm) - Nam có nguy cơ cao hơn
    if (gender == 'male') {
      riskScore += 3;
    }

    // 3. BMI (0-10 điểm)
    final bmi = calculateBMI(heightCm, weightKg);
    if (bmi >= 30) {
      riskScore += 10;
    } else if (bmi >= 25) {
      riskScore += 6;
    } else if (bmi >= 23) {
      riskScore += 3;
    }

    // 4. Huyết áp (0-20 điểm)
    if (systolicBP >= 180 || diastolicBP >= 110) {
      riskScore += 20; // Tăng huyết áp độ 3
    } else if (systolicBP >= 160 || diastolicBP >= 100) {
      riskScore += 15; // Tăng huyết áp độ 2
    } else if (systolicBP >= 140 || diastolicBP >= 90) {
      riskScore += 10; // Tăng huyết áp độ 1
    } else if (systolicBP >= 130 || diastolicBP >= 85) {
      riskScore += 5; // Tiền tăng huyết áp
    }

    // 5. Cholesterol (0-10 điểm)
    if (cholesterol >= 240) {
      riskScore += 10; // Cao
    } else if (cholesterol >= 200) {
      riskScore += 6; // Biên cao
    } else if (cholesterol >= 180) {
      riskScore += 3;
    }

    // 6. Đường huyết (0-8 điểm)
    if (glucose >= 126) {
      riskScore += 8; // Tiểu đường
    } else if (glucose >= 100) {
      riskScore += 5; // Tiền tiểu đường
    }

    // 7. Tăng huyết áp (0-10 điểm)
    if (hypertension) {
      riskScore += 10;
    }

    // 8. Bệnh tim (0-12 điểm)
    if (heartDisease) {
      riskScore += 12;
    }

    // 9. Hút thuốc (0-10 điểm)
    if (smoking) {
      riskScore += 10;
    }

    // 10. Loại công việc (0-5 điểm)
    if (workType == 'sedentary') {
      riskScore += 5;
    } else if (workType == 'moderate') {
      riskScore += 2;
    }

    // Chuẩn hóa điểm về thang 0-100
    riskScore = min(100, riskScore);

    // Xác định mức độ nguy cơ
    String riskLevel;
    String riskLevelVi;
    if (riskScore >= 65) {
      riskLevel = 'high';
      riskLevelVi = 'Nguy cơ cao';
    } else if (riskScore >= 35) {
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
      'bpCategory': _getBPCategory(systolicBP, diastolicBP),
      'cholesterolCategory': _getCholesterolCategory(cholesterol),
      'predictionMethod': 'Rule-based',
    };
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Thừa cân nhẹ';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  String _getBPCategory(double systolic, double diastolic) {
    if (systolic >= 180 || diastolic >= 110) return 'Tăng huyết áp độ 3';
    if (systolic >= 160 || diastolic >= 100) return 'Tăng huyết áp độ 2';
    if (systolic >= 140 || diastolic >= 90) return 'Tăng huyết áp độ 1';
    if (systolic >= 130 || diastolic >= 85) return 'Tiền tăng huyết áp';
    return 'Bình thường';
  }

  String _getCholesterolCategory(double cholesterol) {
    if (cholesterol >= 240) return 'Cao';
    if (cholesterol >= 200) return 'Biên cao';
    return 'Bình thường';
  }

  /// Lưu kết quả dự đoán vào Firebase
  Future<Map<String, dynamic>> savePredictionResult({
    required String userId,
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> predictionResult,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final predictionId = 'stroke_$userId\_$timestamp';

      final data = {
        'id': predictionId,
        'userId': userId,
        'type': 'stroke',
        'riskScore': predictionResult['riskScore'],
        'riskLevel': predictionResult['riskLevel'],
        'riskLevelVi': predictionResult['riskLevelVi'],
        'bmi': predictionResult['bmi'],
        'bmiCategory': predictionResult['bmiCategory'],
        'bpCategory': predictionResult['bpCategory'],
        'cholesterolCategory': predictionResult['cholesterolCategory'],
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
        'type': 'stroke',
        'riskLevel': predictionResult['riskLevel'],
        'createdAt': ServerValue.timestamp,
      });

      print('✅ Đã lưu kết quả dự đoán đột quỵ: $predictionId');

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
      print('🔍 Đang tìm dự đoán đột quỵ cho userId: $userId');
      
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
        
        if (predUserId == userId && predType == 'stroke') {
          predictions.add(prediction);
        }
      });

      print('✅ Tìm thấy ${predictions.length} dự đoán đột quỵ cho user $userId');

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
        'lifestyle': [
          'Bỏ thuốc lá ngay lập tức nếu đang hút thuốc.',
          'Hạn chế rượu bia và các chất kích thích.',
          'Duy trì cân nặng hợp lý, giảm cân nếu thừa cân/béo phì.',
          'Ngủ đủ 7-8 tiếng mỗi đêm, tránh stress.',
        ],
        'diet': [
          'Giảm muối trong chế độ ăn (< 5g/ngày).',
          'Tăng cường rau xanh, trái cây, ngũ cốc nguyên hạt.',
          'Hạn chế thực phẩm nhiều cholesterol và chất béo bão hòa.',
          'Ăn cá giàu omega-3 ít nhất 2 lần/tuần.',
        ],
        'exercise': [
          'Tập thể dục ít nhất 30 phút mỗi ngày, 5 ngày/tuần.',
          'Kết hợp cardio và bài tập sức mạnh.',
          'Tránh vận động quá sức, tập dần dần.',
        ],
        'monitoring': [
          'Kiểm tra huyết áp hàng ngày.',
          'Khám sức khỏe định kỳ 3 tháng/lần.',
          'Uống thuốc đúng theo chỉ định của bác sĩ.',
          'Đến bệnh viện ngay nếu có dấu hiệu: yếu tay chân đột ngột, méo miệng, nói khó.',
        ],
      };
    } else if (riskLevel == 'medium') {
      return {
        'lifestyle': [
          'Bỏ thuốc lá nếu đang hút.',
          'Hạn chế rượu bia.',
          'Quản lý stress hiệu quả.',
          'Duy trì cân nặng hợp lý.',
        ],
        'diet': [
          'Giảm muối và đồ ăn chế biến sẵn.',
          'Tăng rau xanh và trái cây.',
          'Hạn chế thức ăn nhiều dầu mỡ.',
        ],
        'exercise': [
          'Tập thể dục đều đặn 30 phút/ngày.',
          'Đi bộ, bơi lội, đạp xe.',
          'Tránh ngồi lâu một chỗ.',
        ],
        'monitoring': [
          'Kiểm tra huyết áp định kỳ.',
          'Khám sức khỏe 6 tháng/lần.',
          'Theo dõi các chỉ số sức khỏe.',
        ],
      };
    } else {
      return {
        'lifestyle': [
          'Duy trì lối sống lành mạnh.',
          'Không hút thuốc, hạn chế rượu bia.',
          'Ngủ đủ giấc, tránh stress.',
        ],
        'diet': [
          'Ăn uống cân bằng và đa dạng.',
          'Nhiều rau xanh, trái cây.',
          'Hạn chế đồ ngọt và thức ăn nhanh.',
        ],
        'exercise': [
          'Duy trì hoạt động thể chất đều đặn.',
          'Tìm hoạt động vận động yêu thích.',
        ],
        'monitoring': [
          'Khám sức khỏe định kỳ hàng năm.',
          'Duy trì lối sống lành mạnh.',
        ],
      };
    }
  }
}
