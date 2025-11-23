"""
Robust model loader with error handling
"""

import pickle
import numpy as np
import json
import sys

def load_pickle_safe(filename):
    """Try different methods to load pickle file"""
    methods = [
        lambda f: pickle.load(f),
        lambda f: pickle.load(f, encoding='latin1'),
        lambda f: pickle.load(f, encoding='bytes'),
    ]
    
    for i, method in enumerate(methods):
        try:
            with open(filename, 'rb') as f:
                obj = method(f)
            print(f"✅ Loaded {filename} using method {i+1}")
            return obj
        except Exception as e:
            print(f"❌ Method {i+1} failed for {filename}: {e}")
            continue
    
    raise Exception(f"Could not load {filename} with any method")

try:
    print("=" * 60)
    print("Loading models...")
    print("=" * 60)
    
    model = load_pickle_safe('moHinhDotQuy_final.pkl')
    print(f"\n📊 Model type: {type(model).__name__}")
    print(f"Model class: {model.__class__}")
    
    preprocessor = load_pickle_safe('preprocessor.pkl')
    print(f"\n🔧 Preprocessor type: {type(preprocessor).__name__}")
    
    # Try to load model_info
    try:
        model_info_pkl = load_pickle_safe('model_info.pkl')
        print(f"\n📋 Model info loaded: {model_info_pkl}")
    except Exception as e:
        print(f"\n⚠️ Could not load model_info.pkl: {e}")
        model_info_pkl = None
    
    print("\n" + "=" * 60)
    print("Model Analysis")
    print("=" * 60)
    
    # Analyze model
    info = {
        'model_type': type(model).__name__,
        'model_class': str(model.__class__),
    }
    
    # Get model attributes
    if hasattr(model, 'n_features_in_'):
        info['n_features'] = int(model.n_features_in_)
        print(f"Number of features: {info['n_features']}")
    
    if hasattr(model, 'n_estimators'):
        info['n_estimators'] = model.n_estimators
        print(f"Number of estimators: {info['n_estimators']}")
    
    if hasattr(model, 'max_depth'):
        info['max_depth'] = model.max_depth
        print(f"Max depth: {info['max_depth']}")
    
    if hasattr(model, 'classes_'):
        info['classes'] = model.classes_.tolist()
        print(f"Classes: {info['classes']}")
    
    # Analyze preprocessor
    print(f"\nPreprocessor attributes:")
    if hasattr(preprocessor, 'mean_'):
        info['scaler_mean'] = preprocessor.mean_.tolist()
        print(f"  Mean: {preprocessor.mean_}")
    
    if hasattr(preprocessor, 'scale_'):
        info['scaler_scale'] = preprocessor.scale_.tolist()
        print(f"  Scale: {preprocessor.scale_}")
    
    if hasattr(preprocessor, 'var_'):
        print(f"  Variance: {preprocessor.var_}")
    
    # Get feature names
    feature_names = None
    if hasattr(preprocessor, 'get_feature_names_out'):
        try:
            feature_names = preprocessor.get_feature_names_out().tolist()
            info['feature_names'] = feature_names
            print(f"\nFeature names: {feature_names}")
        except:
            pass
    
    if hasattr(preprocessor, 'feature_names_in_'):
        feature_names = preprocessor.feature_names_in_.tolist()
        info['feature_names'] = feature_names
        print(f"\nFeature names (in): {feature_names}")
    
    # Save info
    with open('model_analysis.json', 'w') as f:
        json.dump(info, f, indent=2)
    
    print("\n✅ Model analysis saved to model_analysis.json")
    
    # Test prediction
    print("\n" + "=" * 60)
    print("Testing Prediction")
    print("=" * 60)
    
    # Create sample input (11 features based on our app)
    sample = np.array([[
        50,   # age
        1,    # gender (1=male, 0=female)
        25.0, # bmi
        140,  # systolic BP
        90,   # diastolic BP
        200,  # cholesterol
        100,  # glucose
        1,    # hypertension
        0,    # heart disease
        0,    # smoking
        1,    # work type (0=sedentary, 1=moderate, 2=active)
    ]])
    
    print(f"Sample input shape: {sample.shape}")
    print(f"Sample input:\n{sample}")
    
    # Preprocess
    processed = preprocessor.transform(sample)
    print(f"\nProcessed shape: {processed.shape}")
    print(f"Processed data:\n{processed}")
    
    # Predict
    prediction_proba = model.predict_proba(processed)
    prediction_class = model.predict(processed)
    
    print(f"\nPrediction probabilities: {prediction_proba}")
    print(f"Predicted class: {prediction_class}")
    print(f"Stroke probability: {prediction_proba[0][1]:.2%}")
    
    print("\n✅ Model is working correctly!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
