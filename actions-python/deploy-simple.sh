#!/bin/bash

# Skip Docker build due to permission issues
echo "Skipping Docker build due to permission issues..."

# Deploy the action with appropriate memory and timeout for ML workloads
# Using 512MB memory to stay within OpenWhisk limits
wsk -i action create python-image-classifier --kind python:3 action.py --memory 512 --timeout 60000

echo "Python image classifier action deployed with basic runtime (no TensorFlow)"
echo ""
echo "To test with an image URL, run:"
echo "wsk -i action invoke python-image-classifier -r -p url \"https://www.bestpets.co/wp-content/uploads/2017/08/e38767b2d4005b865e1854c265e9ab7e.jpg\""