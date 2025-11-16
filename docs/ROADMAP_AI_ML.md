# 🤖 ROADMAP: AI/ML PREDICTION SYSTEM

**Mục tiêu:** Tích hợp mô hình AI/ML để dự đoán đột quỵ và tiểu đường  
**Thời gian ước tính:** 4-6 tuần (sau khi có model .pkl)  
**Điều kiện tiên quyết:** Có model .pkl đã train và test

---

## 📋 YÊU CẦU TRƯỚC KHI BẮT ĐẦU

### 1. Model Requirements
- [ ] **Stroke prediction model** (.pkl hoặc .h5)
- [ ] **Diabetes prediction model** (.pkl hoặc .h5)
- [ ] **Model metadata:**
  - Input features và data types
  - Output format (probability, class, etc.)
  - Preprocessing steps
  - Model accuracy/metrics

### 2. Technical Requirements
- [ ] Python backend (Flask/FastAPI)
- [ ] Model serving infrastructure
- [ ] API documentation

---

## 🎯 PHASE 1: BACKEND SETUP (Tuần 1-2)

### Week 1: Python Backend

#### 1.1. Setup Flask/FastAPI Server
```python
# app.py
from flask import Flask, request, jsonify
import pickle
import numpy as np

app = Flask(__name__)

# Load models
stroke_model = pickle.load(open('stroke_model.pkl', 'rb'))
diabetes_model = pickle.load(open('diabetes_model.pkl', 'rb'))

@app.route('/predict/stroke', methods=['POST'])
def predict_stroke():
    data = request.json
    # Preprocessing
    features = preprocess_stroke_data(data)
    # Prediction
    prediction = stroke_model.predict_proba([features])
    return jsonify({
        'probability': float(prediction[0][1]),
        'risk_level': get_risk_level(prediction[0][1])
    })

@app.route('/predict/diabetes', methods=['POST'])
def predict_diabetes():
    # Similar implementation
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### 1.2. Preprocessing Functions
```python
def preprocess_stroke_data(data):
    """
    Convert input data to model format
    """
    # Example features
    age = data['age']
    gender = 1 if data['gender'] == 'male' else 0
    hypertension = 1 if data['hypertension'] else 0
    heart_disease = 1 if data['heartDisease'] else 0
    avg_glucose = data['avgGlucoseLevel']
    bmi = data['bmi']
    smoking = encode_smoking(data['smokingStatus'])
    
    return [age, gender, hypertension, heart_disease, 
            avg_glucose, bmi, smoking]

def encode_smoking(status):
    mapping = {
        'never smoked': 0,
        'formerly smoked': 1,
        'smokes': 2
    }
    return mapping.get(status, 0)

def get_risk_level(probability):
    if probability < 0.3:
        return 'low'
    elif probability < 0.6:
        return 'medium'
    else:
        return 'high'
```

#### 1.3. Deliverables
- ✅ Flask/FastAPI server running
- ✅ Models loaded successfully
- ✅ API endpoints working
- ✅ Preprocessing functions tested

---

### Week 2: Deployment & API

#### 2.1. Deployment Options

**Option A: Firebase Cloud Functions (Python)**
```python
# main.py
from firebase_functions import https_fn
import pickle

@https_fn.on_request()
def predict_stroke(req: https_fn.Request) -> https_fn.Response:
    # Implementation
    pass
```

**Option B: Google Cloud Run**
```dockerfile
# Dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

**Option C: Heroku**
```bash
heroku create sews-ml-api
git push heroku main
```

#### 2.2. API Documentation
```yaml
# openapi.yaml
openapi: 3.0.0
info:
  title: SEWS ML API
  version: 1.0.0

paths:
  /predict/stroke:
    post:
      summary: Predict stroke risk
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                age: {type: integer}
                gender: {type: string}
                hypertension: {type: boolean}
                heartDisease: {type: boolean}
                avgGlucoseLevel: {type: number}
                bmi: {type: number}
                smokingStatus: {type: string}
      responses:
        200:
          description: Prediction result
          content:
            application/json:
              schema:
                type: object
                properties:
                  probability: {type: number}
                  risk_level: {type: string}
```

#### 2.3. Deliverables
- ✅ API deployed và accessible
- ✅ API documentation
- ✅ API key/authentication setup
- ✅ Rate limiting

---

## 🎯 PHASE 2: FLUTTER INTEGRATION (Tuần 3-4)

### Week 3: API Service

#### 3.1. Create PredictionService
```dart
// lib/services/prediction_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictionService {
  static const String _baseUrl = 'https://your-api.com';
  static const String _apiKey = 'your-api-key';

  Future<Map<String, dynamic>> predictStroke({
    required int age,
    required String gender,
    required bool hypertension,
    required bool heartDisease,
    required double avgGlucoseLevel,
    required double bmi,
    required String smokingStatus,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict/stroke'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'hypertension': hypertension,
          'heartDisease': heartDisease,
          'avgGlucoseLevel': avgGlucoseLevel,
          'bmi': bmi,
          'smokingStatus': smokingStatus,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> predictDiabetes({
    required int age,
    required double bmi,
    required int bloodPressure,
    required int glucose,
    required int insulin,
    required bool familyHistory,
  }) async {
    // Similar implementation
  }

  Future<void> savePredictionResult({
    required String userId,
    required String type,
    required Map<String, dynamic> result,
    required Map<String, dynamic> inputData,
  }) async {
    final db = FirebaseDatabase.instance;
    final ref = db.ref('prediction_results').push();
    
    await ref.set({
      'userId': userId,
      'type': type,
      'probability': result['probability'],
      'riskLevel': result['risk_level'],
      'inputData': inputData,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
```

#### 3.2. Dependencies
```yaml
http: ^1.1.0
```

#### 3.3. Deliverables
- ✅ PredictionService hoàn chỉnh
- ✅ Error handling
- ✅ Lưu kết quả vào Firebase

---

### Week 4: UI Integration

#### 4.1. Update Stroke Form
```dart
// lib/features/user/prediction/screen_stroke_form.dart
class ScreenStrokeForm extends StatefulWidget {
  @override
  State<ScreenStrokeForm> createState() => _ScreenStrokeFormState();
}

class _ScreenStrokeFormState extends State<ScreenStrokeForm> {
  final _formKey = GlobalKey<FormState>();
  final _predictionService = PredictionService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  
  // Form fields
  int _age = 0;
  String _gender = 'male';
  bool _hypertension = false;
  bool _heartDisease = false;
  double _avgGlucoseLevel = 0;
  double _bmi = 0;
  String _smokingStatus = 'never smoked';

  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _predictionService.predictStroke(
        age: _age,
        gender: _gender,
        hypertension: _hypertension,
        heartDisease: _heartDisease,
        avgGlucoseLevel: _avgGlucoseLevel,
        bmi: _bmi,
        smokingStatus: _smokingStatus,
      );
      
      // Save to Firebase
      final userId = await _authService.getUserId();
      await _predictionService.savePredictionResult(
        userId: userId!,
        type: 'stroke',
        result: result,
        inputData: {
          'age': _age,
          'gender': _gender,
          'hypertension': _hypertension,
          'heartDisease': _heartDisease,
          'avgGlucoseLevel': _avgGlucoseLevel,
          'bmi': _bmi,
          'smokingStatus': _smokingStatus,
        },
      );
      
      // Navigate to result
      Navigator.pushNamed(
        context,
        '/stroke-result',
        arguments: result,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Form fields...
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submitPrediction,
              child: _isLoading
                ? CircularProgressIndicator()
                : Text('Dự Đoán Nguy Cơ'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 4.2. Update Result Screen
```dart
// lib/features/user/prediction/screen_stroke_result.dart
class ScreenStrokeResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)!.settings.arguments 
        as Map<String, dynamic>;
    
    final probability = result['probability'] as double;
    final riskLevel = result['risk_level'] as String;
    
    return Scaffold(
      body: Column(
        children: [
          // Risk gauge/chart
          _RiskGauge(probability: probability),
          
          // Risk level
          _RiskLevelCard(level: riskLevel),
          
          // Recommendations
          _RecommendationsSection(level: riskLevel),
          
          // Actions
          ElevatedButton(
            onPressed: () {
              // Book appointment
            },
            child: Text('Đặt lịch khám'),
          ),
        ],
      ),
    );
  }
}
```

#### 4.3. Deliverables
- ✅ Form gửi data đến API
- ✅ Hiển thị loading state
- ✅ Hiển thị kết quả với UI đẹp
- ✅ Lưu lịch sử dự đoán

---

## 🎯 PHASE 3: ADVANCED FEATURES (Tuần 5-6)

### Week 5: History & Analytics

#### 5.1. Health History Screen
```dart
// lib/features/user/health/screen_health_history.dart
class ScreenHealthHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _getPredictionHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final predictions = snapshot.data as List;
          
          return Column(
            children: [
              // Chart showing trend
              _TrendChart(predictions: predictions),
              
              // List of predictions
              Expanded(
                child: ListView.builder(
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    return _PredictionHistoryCard(
                      prediction: predictions[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Stream<List> _getPredictionHistory() {
    // Load from Firebase
  }
}
```

#### 5.2. Trend Chart
```dart
import 'package:fl_chart/fl_chart.dart';

class _TrendChart extends StatelessWidget {
  final List predictions;
  
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: predictions.map((p) {
              return FlSpot(
                p['createdAt'].millisecondsSinceEpoch.toDouble(),
                p['probability'] * 100,
              );
            }).toList(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
```

#### 5.3. Deliverables
- ✅ Lịch sử dự đoán
- ✅ Biểu đồ xu hướng
- ✅ So sánh kết quả
- ✅ Export PDF

---

### Week 6: Recommendations & Alerts

#### 6.1. Smart Recommendations
```dart
class RecommendationService {
  List<String> getRecommendations({
    required String riskLevel,
    required Map<String, dynamic> inputData,
  }) {
    List<String> recommendations = [];
    
    if (riskLevel == 'high') {
      recommendations.add('🚨 Nguy cơ cao - Cần khám bác sĩ ngay');
      recommendations.add('📞 Đặt lịch hẹn với bác sĩ tim mạch');
    }
    
    if (inputData['hypertension'] == true) {
      recommendations.add('💊 Theo dõi huyết áp hàng ngày');
      recommendations.add('🧂 Giảm muối trong chế độ ăn');
    }
    
    if (inputData['bmi'] > 25) {
      recommendations.add('🏃 Tăng cường vận động');
      recommendations.add('🥗 Chế độ ăn lành mạnh');
    }
    
    if (inputData['smokingStatus'] == 'smokes') {
      recommendations.add('🚭 Bỏ thuốc lá ngay');
    }
    
    return recommendations;
  }
}
```

#### 6.2. Auto Alerts
```dart
Future<void> checkAndSendAlerts({
  required String userId,
  required double probability,
  required String riskLevel,
}) async {
  if (riskLevel == 'high') {
    // Send notification to user
    await NotificationService().showNotification(
      title: 'Cảnh báo nguy cơ cao',
      body: 'Kết quả dự đoán cho thấy nguy cơ cao. Vui lòng khám bác sĩ.',
    );
    
    // Notify family members
    final familyMembers = await FamilyService().getFamilyMembers(userId);
    for (var member in familyMembers) {
      await NotificationService().sendToUser(
        userId: member['memberId'],
        title: 'Cảnh báo về người thân',
        body: 'Người thân của bạn có nguy cơ sức khỏe cao.',
      );
    }
    
    // Create alert in database
    await FirebaseDatabase.instance.ref('alerts').push().set({
      'userId': userId,
      'type': 'high_risk_prediction',
      'probability': probability,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
```

#### 6.3. Deliverables
- ✅ Recommendations dựa trên kết quả
- ✅ Auto alerts cho nguy cơ cao
- ✅ Thông báo cho người thân
- ✅ Gợi ý đặt lịch khám

---

## 📦 DEPENDENCIES

```yaml
# API calls
http: ^1.1.0

# Charts
fl_chart: ^0.65.0

# PDF export
pdf: ^3.10.7
printing: ^5.11.1
path_provider: ^2.1.1
```

---

## 🔒 SECURITY & PRIVACY

### 1. API Security
- [ ] API key authentication
- [ ] Rate limiting
- [ ] HTTPS only
- [ ] Input validation

### 2. Data Privacy
- [ ] Encrypt sensitive data
- [ ] GDPR compliance
- [ ] User consent
- [ ] Data retention policy

### 3. Model Security
- [ ] Model versioning
- [ ] A/B testing
- [ ] Monitoring predictions
- [ ] Fallback mechanism

---

## 📊 MONITORING & METRICS

### 1. Technical Metrics
- API response time < 2s
- Prediction accuracy > 85%
- API uptime > 99%
- Error rate < 1%

### 2. Business Metrics
- Number of predictions per day
- High-risk predictions ratio
- User engagement with recommendations
- Appointment booking rate after high-risk prediction

---

## 🧪 TESTING

### 1. Model Testing
```python
# test_model.py
def test_stroke_prediction():
    # Test cases
    test_data = {
        'age': 65,
        'gender': 'male',
        'hypertension': True,
        'heartDisease': True,
        'avgGlucoseLevel': 228.5,
        'bmi': 28.5,
        'smokingStatus': 'formerly smoked'
    }
    
    result = predict_stroke(test_data)
    assert result['risk_level'] == 'high'
    assert 0 <= result['probability'] <= 1
```

### 2. API Testing
```dart
// test/services/prediction_service_test.dart
void main() {
  test('Stroke prediction returns valid result', () async {
    final service = PredictionService();
    final result = await service.predictStroke(
      age: 65,
      gender: 'male',
      hypertension: true,
      heartDisease: true,
      avgGlucoseLevel: 228.5,
      bmi: 28.5,
      smokingStatus: 'formerly smoked',
    );
    
    expect(result['probability'], isA<double>());
    expect(result['risk_level'], isIn(['low', 'medium', 'high']));
  });
}
```

---

## 🚀 DEPLOYMENT CHECKLIST

- [ ] Model trained và tested
- [ ] API deployed và accessible
- [ ] API documentation complete
- [ ] Flutter integration tested
- [ ] Error handling implemented
- [ ] Security measures in place
- [ ] Monitoring setup
- [ ] User testing completed
- [ ] Performance optimized
- [ ] Ready for production

---

## 📝 NOTES

- **Model updates:** Plan for model retraining và versioning
- **Feedback loop:** Collect user feedback để improve model
- **Explainability:** Giải thích tại sao model đưa ra prediction đó
- **Compliance:** Đảm bảo tuân thủ quy định y tế

---

*Roadmap AI/ML được tạo bởi Kiro AI - 16/11/2025*
