"""
Alternative: Export model predictions as a lookup table or simpler format
Since TensorFlow doesn't support Python 3.14 yet, we'll create a workaround
"""

import pickle
import numpy as np
import json

print("Loading models...")
with open('moHinhDotQuy_final.pkl', 'rb') as f:
    model = pickle.load(f)

with open('preprocessor.pkl', 'rb') as f:
    preprocessor = pickle.load(f)

print(f"Model type: {type(model).__name__}")
print(f"Model: {model}")

# Get feature information
if hasattr(preprocessor, 'get_feature_names_out'):
    feature_names = preprocessor.get_feature_names_out()
else:
    feature_names = None

print(f"Features: {feature_names}")

# Export model parameters for Flutter implementation
model_info = {
    'model_type': type(model).__name__,
    'n_features': model.n_features_in_ if hasattr(model, 'n_features_in_') else None,
    'feature_names': list(feature_names) if feature_names is not None else [],
}

# For RandomForest, we can export tree structure
if hasattr(model, 'estimators_'):
    model_info['n_estimators'] = len(model.estimators_)
    model_info['max_depth'] = model.max_depth
    
# Export preprocessing info
if hasattr(preprocessor, 'mean_'):
    model_info['scaler_mean'] = preprocessor.mean_.tolist()
    model_info['scaler_scale'] = preprocessor.scale_.tolist()

print("\nModel Info:")
print(json.dumps(model_info, indent=2))

# Save model info
with open('model_info_export.json', 'w') as f:
    json.dump(model_info, f, indent=2)

print("\n✅ Model info exported to model_info_export.json")

# Test prediction with sample data
print("\n🧪 Testing prediction...")
sample_input = np.array([[
    50,  # age
    1,   # gender (male)
    25,  # bmi
    140, # systolic BP
    90,  # diastolic BP
    200, # cholesterol
    100, # glucose
    1,   # hypertension
    0,   # heart disease
    0,   # smoking
    1,   # work type
]])

print(f"Sample input shape: {sample_input.shape}")
processed = preprocessor.transform(sample_input)
print(f"Processed shape: {processed.shape}")

prediction = model.predict_proba(processed)
print(f"Prediction: {prediction}")
print(f"Stroke probability: {prediction[0][1]:.2%}")
