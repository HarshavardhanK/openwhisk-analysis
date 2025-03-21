#!/bin/bash

# Set your DockerHub username
DOCKER_USERNAME="tsarshah"
IMAGE_NAME="face-detection-openwhisk"
IMAGE_TAG="latest"

# Copy the actionproxy.py from parent directory
cp ../actionproxy.py .

# Build the custom face detection runtime Docker image
echo "Building face detection runtime Docker image..."
sudo docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .

# No push for now - just build locally
echo "Face detection runtime image built successfully!"
echo "Use this image as a custom runtime with: --docker ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"