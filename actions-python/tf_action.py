#!/usr/bin/env python

import sys
import json
import base64
import numpy as np
from PIL import Image
import io
import urllib.request
import tensorflow as tf

def verify():
    """Verify TensorFlow installation"""
    print(f"TensorFlow version: {tf.__version__}")
    return 0

def preprocess_image(image, target_size=(224, 224)):
    """Preprocess image for model input"""
    # Resize image to target size
    image = image.resize(target_size)
    
    # Convert to array and expand dimensions
    img_array = np.array(image)
    img_array = np.expand_dims(img_array, axis=0)
    
    # Preprocess for MobileNetV2
    img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
    
    return img_array

def load_model():
    """Load and return the pre-trained model"""
    # Load MobileNetV2 pre-trained model with reduced size
    model = tf.keras.applications.MobileNetV2(
        input_shape=(224, 224, 3),
        include_top=True,
        weights='imagenet',
        alpha=0.35  # Use the smallest variant (35% of filters)
    )
    return model

def main(args):
    """Image classification function for OpenWhisk"""
    try:
        # Check for verify command (used during initialization)
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
        
        # Basic image processing
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Get image format and size
        format_name = image.format or "Unknown"
        width, height = image.size
        
        # Preprocess the image for the model
        processed_image = preprocess_image(image)
        
        # Load the model (could be cached in a production environment)
        model = load_model()
        
        # Reduce precision to save memory
        try:
            import tensorflow as tf
            if hasattr(tf, 'keras'):
                tf.keras.mixed_precision.set_global_policy('mixed_float16')
        except:
            pass
            
        # Make prediction
        predictions = model.predict(processed_image, batch_size=1)
        
        # Decode predictions
        decoded_predictions = tf.keras.applications.mobilenet_v2.decode_predictions(
            predictions, top=5
        )[0]
        
        # Format results
        results = []
        for _, label, confidence in decoded_predictions:
            results.append({
                'class': label,
                'confidence': float(confidence)
            })
        
        return {
            'message': 'Image classified successfully',
            'image_info': {
                'format': format_name,
                'width': width,
                'height': height
            },
            'classification': results,
            'model': 'MobileNetV2'
        }
    
    except Exception as e:
        return {
            'error': str(e),
            'message': 'Error processing image'
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