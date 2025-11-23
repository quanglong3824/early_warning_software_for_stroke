"""
Script để convert model scikit-learn sang TensorFlow Lite
Sử dụng: python convert_to_tflite.py
"""

import pickle
import numpy as np
import json
import tensorflow as tf
from sklearn.ensemble import RandomForestClassifier
import os

# Load models
print("Loading models...")
with open('moHinhDotQuy_final.pkl', 'rb') as f:
    model = pickle.load(f)

with open('preprocessor.pkl', 'rb') as f:
    preprocessor = pickle.load(f)

with open('model_info.pkl', 'rb') as f:
    model_info = pickle.load(f)

print(f"Model type: {type(model).__name__}")
print(f"Model info: {model_info}")

# Get feature names
feature_names = preprocessor.get_feature_names_out() if hasattr(preprocessor, 'get_feature_names_out') else None
print(f"Features: {feature_names}")

# Create a simple wrapper model using TensorFlow
class StrokePredictor(tf.Module):
    def __init__(self, sklearn_model, sklearn_preprocessor):
        super().__init__()
        self.model = sklearn_model
        self.preprocessor = sklearn_preprocessor
    
    @tf.function(input_signature=[tf.TensorSpec(shape=[None, None], dtype=tf.float32)])
    def predict(self, x):
        # Convert to numpy for sklearn
        x_np = x.numpy()
        
        # Preprocess
        x_processed = self.preprocessor.transform(x_np)
        
        # Predict
        predictions = self.model.predict_proba(x_processed)
        
        # Return as tensor
        return tf.constant(predictions, dtype=tf.float32)

# Create wrapper
print("Creating TensorFlow wrapper...")
predictor = StrokePredictor(model, preprocessor)

# Save as SavedModel
print("Saving as SavedModel...")
tf.saved_model.save(predictor, 'saved_model')

# Convert to TFLite
print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_saved_model('saved_model')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save TFLite model
with open('stroke_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("✅ Model converted successfully!")
print(f"Output: stroke_model.tflite ({len(tflite_model)} bytes)")

# Save metadata
metadata = {
    'model_type': type(model).__name__,
    'input_shape': list(preprocessor.transform(np.zeros((1, len(feature_names)))).shape) if feature_names else None,
    'output_shape': [1, 2],  # Binary classification: [no_stroke_prob, stroke_prob]
    'feature_names': list(feature_names) if feature_names else [],
    'preprocessing': str(type(preprocessor).__name__),
}

with open('model_metadata.json', 'w') as f:
    json.dump(metadata, f, indent=2)

print("✅ Metadata saved to model_metadata.json")
print(json.dumps(metadata, indent=2))
