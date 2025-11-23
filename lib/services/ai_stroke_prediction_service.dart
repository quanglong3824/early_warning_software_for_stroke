import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service để gọi Flask API dự đoán đột quỵ
class AIStrokePredictionService {
  static final AIStrokePredictionService _instance = AIStrokePredictionService._internal();
  factory AIStrokePredictionService() => _instance;
  AIStrokePredictionService._internal();

  // API endpoint - Change this to your server URL
  String _apiUrl = 'http://localhost:5001';
  
  /// Set API URL (for production deployment)
  void setApiUrl(String url) {
    _apiUrl = url;
  }

  /// Check if API server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API Health: ${data['status']}');
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('❌ API Health check failed: $e');
      return false;
    }
  }

  /// Predict stroke risk using Flask API
  Future<Map<String, dynamic>?> predictStrokeRisk({
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
  }) async {
    try {
      final requestBody = {
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'cholesterol': cholesterol,
        'glucose': glucose,
        'hypertension': hypertension,
        'heartDisease': heartDisease,
        'smoking': smoking,
        'workType': workType,
      };

      print('🔄 Calling API: $_apiUrl/predict');
      print('📤 Request: $requestBody');

      final response = await http.post(
        Uri.parse('$_apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ API Prediction successful');
          return {
            'riskScore': data['riskScore'],
            'riskLevel': data['riskLevel'],
            'riskLevelVi': data['riskLevelVi'],
            'bmi': data['bmi'],
            'bmiCategory': data['bmiCategory'],
            'bpCategory': data['bpCategory'],
            'cholesterolCategory': data['cholesterolCategory'],
            'strokeProbability': data['strokeProbability'],
            'predictionMethod': data['predictionMethod'],
          };
        } else {
          print('❌ API returned error: ${data['error']}');
          return null;
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error calling API: $e');
      return null;
    }
  }
}
