#!/usr/bin/env python

import sys
import json
import base64
import numpy as np
from PIL import Image
import io
import urllib.request

def main(args):
    """Image classification function for OpenWhisk"""
    try:
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
        
        # Extract basic image information 
        try:
            # Try to extract some colors from the image
            image_small = image.resize((10, 10))
            colors = image_small.getcolors()
            dominant_colors = sorted(colors, key=lambda x: x[0], reverse=True)[:3] if colors else []
            color_values = [color[1] for color in dominant_colors]
        except:
            color_values = []
        
        return {
            'message': 'Image processed successfully',
            'image_info': {
                'format': format_name,
                'width': width,
                'height': height,
                'colors_sample': str(color_values)
            },
            'note': 'This is a lightweight version without TensorFlow classification'
        }
    
    except Exception as e:
        return {
            'error': str(e),
            'message': 'Error processing image'
        }

# OpenWhisk entry point
if __name__ == "__main__":
    # Parse input from stdin
    args = json.loads(sys.stdin.read())
    result = main(args)
    print(json.dumps(result))