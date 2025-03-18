#!/bin/bash

# Set your DockerHub username
DOCKER_USERNAME="tsarshah"
IMAGE_NAME="python-tf-classifier"
IMAGE_TAG="new_container"

echo "Building Docker image..."
sudo docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .

# Docker image already has the necessary setup

echo "Pushing Docker image to DockerHub..."
sudo docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Deploying OpenWhisk action..."
wsk -i action update python-image-classifier --docker ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} --memory 512 --timeout 300000

echo "Python image classifier action deployed successfully"
echo ""
echo "To test with an image URL, run:"
echo "wsk -i action invoke python-image-classifier -r -p url \"https://www.bestpets.co/wp-content/uploads/2017/08/e38767b2d4005b865e1854c265e9ab7e.jpg\""
echo ""
echo "To test with a local image, run:"
echo "BASE64_IMAGE=\$(base64 -w 0 path/to/your/image.jpg)"
echo "wsk -i action invoke python-image-classifier -r -p image \"\$BASE64_IMAGE\""
