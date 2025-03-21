#!/bin/bash

# Set your DockerHub username and runtime image
DOCKER_USERNAME="tsarshah"
RUNTIME_IMAGE="${DOCKER_USERNAME}/tensorflow-openwhisk:latest"
ACTION_NAME="tensorflow-classifier"

# Make action file executable
chmod +x tf_action.py

# No need to create a zip package since we'll use the file directly
echo "Using action file directly..."

# Deploy the action using the custom runtime
echo "Deploying TensorFlow action to OpenWhisk..."
wsk -i action update ${ACTION_NAME} \
    --docker ${RUNTIME_IMAGE} \
    --memory 512 \
    --timeout 300000 \
    tf_action.py

echo "TensorFlow action deployed successfully"
echo ""
echo "To test with an image URL, run:"
echo "wsk -i action invoke ${ACTION_NAME} -r -p url \"https://www.bestpets.co/wp-content/uploads/2017/08/e38767b2d4005b865e1854c265e9ab7e.jpg\""
echo ""
echo "To test with a local image, run:"
echo "BASE64_IMAGE=\$(base64 -w 0 path/to/your/image.jpg)"
echo "wsk -i action invoke ${ACTION_NAME} -r -p image \"\$BASE64_IMAGE\""
echo ""
echo "Note: First invocation might be slow due to cold start and TensorFlow model loading"