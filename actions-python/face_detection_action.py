#!/usr/bin/env python3

import sys
import json
import base64
import numpy as np
import cv2
import io
import urllib.request
from PIL import Image
import tensorflow as tf
import tensorflow_hub as hub

# Constants for face detection
FACE_DETECTION_MODEL = "https://tfhub.dev/tensorflow/tfjs-model/blazeface/1/default/1"
AGE_GENDER_MODEL_PATH = "/action/models/age_gender_model"

# For production, these files would be pre-copied to the container
# Age ranges
AGE_RANGES = ['0-2', '3-9', '10-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70+']

def verify():
    """Verify that dependencies are installed"""
    try:
        print(f"OpenCV version: {cv2.__version__}")
        print(f"TensorFlow version: {tf.__version__}")
        print(f"TensorFlow Hub version: {hub.__version__}")
        return 0
    except Exception as e:
        print(f"Verification error: {str(e)}")
        return 1

def load_face_detection_model():
    """Load and return the face detection model from TF Hub"""
    try:
        # Load BlazeFace for lightweight face detection
        model = hub.load(FACE_DETECTION_MODEL)
        return model
    except Exception as e:
        print(f"Error loading face detection model: {str(e)}")
        return None

def load_age_gender_model():
    """Simulate loading pre-trained age and gender models"""
    # In a real scenario, you would load actual pre-trained models
    # For this example, we'll simulate model prediction
    return "age_gender_model_loaded"

def preprocess_image(image):
    """Preprocess image for model input"""
    # Resize image to model input size
    if image.height > 1000 or image.width > 1000:
        image = image.resize((int(image.width/2), int(image.height/2)))
    
    # Convert to RGB if not already
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Convert to numpy array
    img_array = np.array(image)
    
    # Convert to BGR for OpenCV
    img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
    
    return img_array

def detect_faces(face_model, image_array):
    """Detect faces in the image"""
    # Convert to RGB for model
    rgb_image = cv2.cvtColor(image_array, cv2.COLOR_BGR2RGB)
    
    # Normalize and expand dimensions
    input_img = tf.image.convert_image_dtype(rgb_image, dtype=tf.float32)
    input_img = tf.expand_dims(input_img, axis=0)
    
    # Run prediction
    predictions = face_model(input_img)
    
    return predictions, rgb_image

def predict_age_gender(face_img):
    """Predict age and gender for a face image"""
    # This is a simplified simulation
    # In a real scenario, you would use actual model inference
    
    # Simulate gender prediction (0: male, 1: female)
    gender = np.random.choice(['Male', 'Female'], p=[0.5, 0.5])
    
    # Simulate age prediction (0-8 corresponding to age ranges)
    age_range = np.random.randint(0, len(AGE_RANGES))
    
    return {
        'gender': gender,
        'age_range': AGE_RANGES[age_range],
        'confidence': round(np.random.uniform(0.7, 0.99), 2)
    }

def main(args):
    """Face detection and analysis function for OpenWhisk"""
    try:
        # If verifying installation only
        if len(sys.argv) > 1 and sys.argv[1] == 'verify':
            return verify()
            
        # Get image from URL or base64
        image = None
        
        if 'url' in args:
            # Handle image URL
            with urllib.request.urlopen(args['url']) as response:
                image_data = response.read()
                image = Image.open(io.BytesIO(image_data))
        elif 'image' in args:
            # Handle base64 encoded image
            image_data = base64.b64decode(args['image'])
            image = Image.open(io.BytesIO(image_data))
        else:
            return {
                'error': 'No image provided',
                'message': 'Please provide either an image URL or a base64 encoded image'
            }
        
        # Image metadata
        format_name = image.format or "Unknown"
        width, height = image.size
        
        # Preprocess image
        processed_image = preprocess_image(image)
        
        # Load models
        face_model = load_face_detection_model()
        if face_model is None:
            return {
                'error': 'Failed to load face detection model',
                'message': 'Model loading error'
            }
        
        age_gender_model = load_age_gender_model()
        
        # Detect faces
        face_predictions, rgb_image = detect_faces(face_model, processed_image)
        
        # Process face detections
        face_results = []
        
        # Extract results from BlazeFace model
        result_boxes = face_predictions['detection_boxes'].numpy()
        result_scores = face_predictions['detection_scores'].numpy()
        
        # Loop through detections with scores above threshold
        for i in range(len(result_scores)):
            if result_scores[i] > 0.75:  # Confidence threshold
                # Get box coordinates
                ymin, xmin, ymax, xmax = result_boxes[i]
                h, w, _ = rgb_image.shape
                
                # Convert to pixel coordinates
                xmin = int(xmin * w)
                xmax = int(xmax * w)
                ymin = int(ymin * h)
                ymax = int(ymax * h)
                
                # Extract face
                face_img = rgb_image[ymin:ymax, xmin:xmax]
                
                # Make predictions on the face
                predictions = predict_age_gender(face_img)
                
                # Add to results
                face_results.append({
                    'face_id': i + 1,
                    'confidence': float(result_scores[i]),
                    'position': {
                        'x': xmin,
                        'y': ymin,
                        'width': xmax - xmin,
                        'height': ymax - ymin
                    },
                    'gender': predictions['gender'],
                    'age_range': predictions['age_range'],
                    'prediction_confidence': predictions['confidence']
                })
        
        # Return results
        return {
            'message': 'Face detection completed successfully',
            'image_info': {
                'format': format_name,
                'width': width,
                'height': height
            },
            'number_of_faces': len(face_results),
            'faces': face_results,
            'model': 'BlazeFace + Simulated Age/Gender'
        }
    
    except Exception as e:
        import traceback
        return {
            'error': str(e),
            'message': 'Error processing image',
            'traceback': traceback.format_exc()
        }

# OpenWhisk entry point
if __name__ == "__main__":
    # If no arguments, parse input from stdin (normal operation)
    if len(sys.argv) == 1:
        args = json.loads(sys.stdin.read())
        result = main(args)
        if isinstance(result, dict):
            print(json.dumps(result))
        else:
            sys.exit(result)
    # Handle verification call during initialization
    else:
        sys.exit(main({}))