# Flask API Server for Stroke Prediction

## Setup

### 1. Install Dependencies
```bash
cd assets/models
pip3 install -r requirements.txt
```

### 2. Run Server
```bash
python3 app.py
```

Server will start on `http://localhost:5000`

## API Endpoints

### Health Check
```bash
GET http://localhost:5000/health
```

Response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "preprocessor_loaded": true
}
```

### Predict Stroke Risk
```bash
POST http://localhost:5000/predict
Content-Type: application/json

{
  "age": 50,
  "gender": "male",
  "heightCm": 170,
  "weightKg": 70,
  "systolicBP": 140,
  "diastolicBP": 90,
  "cholesterol": 200,
  "glucose": 100,
  "hypertension": true,
  "heartDisease": false,
  "smoking": false,
  "workType": "moderate"
}
```

Response:
```json
{
  "success": true,
  "riskScore": 45,
  "riskLevel": "medium",
  "riskLevelVi": "Nguy cơ trung bình",
  "strokeProbability": 0.45,
  "bmi": "24.2",
  "bmiCategory": "Bình thường",
  "bpCategory": "Tăng huyết áp độ 1",
  "cholesterolCategory": "Biên cao",
  "predictionMethod": "AI"
}
```

## Flutter Integration

The Flutter app will automatically detect and use the API if it's running.

If API is not available, it falls back to rule-based prediction.

## Deployment

### Local Development
- Run on `localhost:5000`
- Flutter app connects to `http://localhost:5000`

### Production
- Deploy to cloud (Heroku, Railway, Google Cloud Run, etc.)
- Update API URL in Flutter:
  ```dart
  AIStrokePredictionService().setApiUrl('https://your-api.com');
  ```

## Testing

```bash
# Test health check
curl http://localhost:5000/health

# Test prediction
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 50,
    "gender": "male",
    "heightCm": 170,
    "weightKg": 70,
    "systolicBP": 140,
    "diastolicBP": 90,
    "cholesterol": 200,
    "glucose": 100,
    "hypertension": true,
    "heartDisease": false,
    "smoking": false,
    "workType": "moderate"
  }'
```
