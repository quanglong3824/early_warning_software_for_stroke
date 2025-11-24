"""
Flask API Server for Stroke Prediction Model
Run: python app.py
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web

# Load models
print("Loading models...")
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
try:
    with open(os.path.join(BASE_DIR, 'moHinhDotQuy_final.pkl'), 'rb') as f:
        model = joblib.load(f)
    print(f"✅ Model loaded: {type(model).__name__}")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    model = None

try:
    with open(os.path.join(BASE_DIR, 'preprocessor.pkl'), 'rb') as f:
        preprocessor = joblib.load(f)
    print(f"✅ Preprocessor loaded: {type(preprocessor).__name__}")
except Exception as e:
    print(f"❌ Error loading preprocessor: {e}")
    preprocessor = None

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'preprocessor_loaded': preprocessor is not None,
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict stroke risk
    
    Request body:
    {
        "age": 50,
        "gender": "male",  // "male" or "female"
        "heightCm": 170,
        "weightKg": 70,
        "systolicBP": 140,
        "diastolicBP": 90,
        "cholesterol": 200,
        "glucose": 100,
        "hypertension": true,
        "heartDisease": false,
        "smoking": false,
        "workType": "moderate"  // "sedentary", "moderate", "active"
    }
    
    Response:
    {
        "success": true,
        "riskScore": 45,
        "riskLevel": "medium",
        "riskLevelVi": "Nguy cơ trung bình",
        "strokeProbability": 0.45,
        "bmi": "24.2",
        "bmiCategory": "Bình thường",
        "bpCategory": "Tăng huyết áp độ 1",
        "cholesterolCategory": "Biên cao"
    }
    """
    try:
        data = request.json
        
        # Validate input
        required_fields = ['age', 'gender', 'heightCm', 'weightKg', 'systolicBP', 
                          'diastolicBP', 'cholesterol', 'glucose', 'hypertension', 
                          'heartDisease', 'smoking', 'workType']
        
        for field in required_fields:
            if field not in data:
                return jsonify({'success': False, 'error': f'Missing field: {field}'}), 400
        
        # Calculate BMI
        height_m = data['heightCm'] / 100
        bmi = data['weightKg'] / (height_m * height_m)
        
        # Encode categorical variables
        gender_encoded = 1.0 if data['gender'] == 'male' else 0.0
        
        # Feature engineering to match training data
        # Assume ever_married based on age (people over 25 are more likely married)
        ever_married = 1.0 if data['age'] >= 25 else 0.0
        
        # Assume urban residence (can be made configurable later)
        residence_type = 1.0  # 1 = Urban, 0 = Rural
        
        # Work type encoding
        work_type_map = {'sedentary': 'Private', 'moderate': 'Self-employed', 'active': 'Govt_job'}
        work_type_str = work_type_map.get(data['workType'], 'Private')
        
        # Smoking status encoding
        smoking_status = 'formerly smoked' if data['smoking'] else 'never smoked'
        
        # Create engineered features
        # nhomTuoi (age group)
        if data['age'] < 30:
            nhom_tuoi = 0
        elif data['age'] < 45:
            nhom_tuoi = 1
        elif data['age'] < 60:
            nhom_tuoi = 2
        else:
            nhom_tuoi = 3
        
        # nhomBMI (BMI group)
        if bmi < 18.5:
            nhom_bmi = 0
        elif bmi < 23:
            nhom_bmi = 1
        elif bmi < 25:
            nhom_bmi = 2
        elif bmi < 30:
            nhom_bmi = 3
        else:
            nhom_bmi = 4
        
        # nhomGlucose (glucose group)
        if data['glucose'] < 100:
            nhom_glucose = 0
        elif data['glucose'] < 126:
            nhom_glucose = 1
        else:
            nhom_glucose = 2
        
        # diemNguyCo (risk score) - calculated based on risk factors
        diem_nguy_co = 0.0
        if data['hypertension']:
            diem_nguy_co += 1.0
        if data['heartDisease']:
            diem_nguy_co += 1.0
        if data['smoking']:
            diem_nguy_co += 1.0
        if bmi >= 30:
            diem_nguy_co += 1.0
        if data['glucose'] >= 126:
            diem_nguy_co += 1.0
        
        # Prepare input features in the exact order expected by the model
        # Order: gender, age, hypertension, heart_disease, ever_married, work_type,
        #        Residence_type, avg_glucose_level, bmi, smoking_status, 
        #        nhomTuoi, nhomBMI, nhomGlucose, diemNguyCo
        import pandas as pd
        features = pd.DataFrame([[
            data['gender'],
            float(data['age']),
            1 if data['hypertension'] else 0,
            1 if data['heartDisease'] else 0,
            'Yes' if ever_married == 1.0 else 'No',
            work_type_str,
            'Urban' if residence_type == 1.0 else 'Rural',
            float(data['glucose']),
            bmi,
            smoking_status,
            nhom_tuoi,
            nhom_bmi,
            nhom_glucose,
            diem_nguy_co
        ]], columns=['gender', 'age', 'hypertension', 'heart_disease', 'ever_married', 
                     'work_type', 'Residence_type', 'avg_glucose_level', 'bmi', 
                     'smoking_status', 'nhomTuoi', 'nhomBMI', 'nhomGlucose', 'diemNguyCo'])
        
        # Preprocess
        if preprocessor is not None:
            features_processed = preprocessor.transform(features)
        else:
            features_processed = features
        
        # Predict
        if model is not None:
            prediction_proba = model.predict_proba(features_processed)
            stroke_prob = float(prediction_proba[0][1])
            risk_score = int(stroke_prob * 100)
        else:
            # Fallback to rule-based if model not loaded
            risk_score = calculate_rule_based_risk(data, bmi)
            stroke_prob = risk_score / 100.0
        
        # Determine risk level
        if risk_score >= 65:
            risk_level = 'high'
            risk_level_vi = 'Nguy cơ cao'
        elif risk_score >= 35:
            risk_level = 'medium'
            risk_level_vi = 'Nguy cơ trung bình'
        else:
            risk_level = 'low'
            risk_level_vi = 'Nguy cơ thấp'
        
        # Prepare response
        response = {
            'success': True,
            'riskScore': risk_score,
            'riskLevel': risk_level,
            'riskLevelVi': risk_level_vi,
            'strokeProbability': stroke_prob,
            'bmi': f"{bmi:.1f}",
            'bmiCategory': get_bmi_category(bmi),
            'bpCategory': get_bp_category(data['systolicBP'], data['diastolicBP']),
            'cholesterolCategory': get_cholesterol_category(data['cholesterol']),
            'predictionMethod': 'AI' if model is not None else 'Rule-based',
        }
        
        return jsonify(response)
        
    except Exception as e:
        print(f"Error in prediction: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500

def calculate_rule_based_risk(data, bmi):
    """Fallback rule-based calculation"""
    risk_score = 0.0
    
    # Age
    age = data['age']
    if age >= 75: risk_score += 25
    elif age >= 65: risk_score += 20
    elif age >= 55: risk_score += 15
    elif age >= 45: risk_score += 10
    elif age >= 35: risk_score += 5
    
    # Gender
    if data['gender'] == 'male': risk_score += 3
    
    # BMI
    if bmi >= 30: risk_score += 10
    elif bmi >= 25: risk_score += 6
    elif bmi >= 23: risk_score += 3
    
    # Blood pressure
    systolic = data['systolicBP']
    diastolic = data['diastolicBP']
    if systolic >= 180 or diastolic >= 110: risk_score += 20
    elif systolic >= 160 or diastolic >= 100: risk_score += 15
    elif systolic >= 140 or diastolic >= 90: risk_score += 10
    elif systolic >= 130 or diastolic >= 85: risk_score += 5
    
    # Cholesterol
    chol = data['cholesterol']
    if chol >= 240: risk_score += 10
    elif chol >= 200: risk_score += 6
    elif chol >= 180: risk_score += 3
    
    # Glucose
    glucose = data['glucose']
    if glucose >= 126: risk_score += 8
    elif glucose >= 100: risk_score += 5
    
    # Conditions
    if data['hypertension']: risk_score += 10
    if data['heartDisease']: risk_score += 12
    if data['smoking']: risk_score += 10
    
    # Work type
    if data['workType'] == 'sedentary': risk_score += 5
    elif data['workType'] == 'moderate': risk_score += 2
    
    return min(100, int(risk_score))

def get_bmi_category(bmi):
    if bmi < 18.5: return 'Thiếu cân'
    if bmi < 23: return 'Bình thường'
    if bmi < 25: return 'Thừa cân nhẹ'
    if bmi < 30: return 'Thừa cân'
    return 'Béo phì'

def get_bp_category(systolic, diastolic):
    if systolic >= 180 or diastolic >= 110: return 'Tăng huyết áp độ 3'
    if systolic >= 160 or diastolic >= 100: return 'Tăng huyết áp độ 2'
    if systolic >= 140 or diastolic >= 90: return 'Tăng huyết áp độ 1'
    if systolic >= 130 or diastolic >= 85: return 'Tiền tăng huyết áp'
    return 'Bình thường'

def get_cholesterol_category(cholesterol):
    if cholesterol >= 240: return 'Cao'
    if cholesterol >= 200: return 'Biên cao'
    return 'Bình thường'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"\n🚀 Starting Flask API server on port {port}...")
    print(f"📍 Health check: http://localhost:{port}/health")
    print(f"📍 Prediction: http://localhost:{port}/predict")
    app.run(host='0.0.0.0', port=port, debug=True)
