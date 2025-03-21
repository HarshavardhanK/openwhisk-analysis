#!/bin/bash

# Set your DockerHub username and runtime image
DOCKER_USERNAME="tsarshah"
RUNTIME_IMAGE="${DOCKER_USERNAME}/face-detection-openwhisk:latest"
ACTION_NAME="face-detection"

# Build the Docker image
echo "Building Docker image for face detection..."
docker build -t ${RUNTIME_IMAGE} .

# Push the image to DockerHub (uncomment if needed)
# echo "Pushing image to DockerHub..."
# docker push ${RUNTIME_IMAGE}

# Make action file executable
chmod +x face_detection_action.py

# Deploy the action using the custom runtime
echo "Deploying face detection action to OpenWhisk..."
wsk -i action update ${ACTION_NAME} \
    --docker ${RUNTIME_IMAGE} \
    --memory 2048 \
    --timeout 300000 \
    face_detection_action.py

echo "Face detection action deployed successfully"
echo ""
echo "To test with a face image URL, run:"
echo "wsk -i action invoke ${ACTION_NAME} -r -p url \"https://parrotprint.com/wp/wp-content/uploads/2017/04/pexels-photo-27411.jpg\""
echo ""
echo "To test with a local image, run:"
echo "BASE64_IMAGE=\$(base64 -w 0 path/to/your/face-image.jpg)"
echo "wsk -i action invoke ${ACTION_NAME} -r -p image \"\$BASE64_IMAGE\""
echo ""
echo "Note: First invocation might be slow due to cold start and model loading"