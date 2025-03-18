# Python ML Action for OpenWhisk

This directory contains a custom Docker-based solution for running Python ML workloads on OpenWhisk, specifically focusing on image classification using TensorFlow.

## Overview

The solution uses a Docker container based on the official OpenWhisk Python action runtime, extended with TensorFlow and other ML dependencies. This approach avoids the limitations of the standard OpenWhisk Python runtime which lacks TensorFlow support.

## Files

- `Dockerfile`: Extends the OpenWhisk Python action runtime with TensorFlow and other ML dependencies
- `action.py`: The OpenWhisk action code that handles image classification using MobileNetV2
- `deploy.sh`: Script to build, push, and deploy the Docker action to OpenWhisk

## Prerequisites

1. Docker installed and configured
2. DockerHub account (or another container registry)
3. OpenWhisk CLI (`wsk`) configured
4. Sufficient cluster resources for running Docker actions

## Deployment Steps

1. Edit the `deploy.sh` script to set your DockerHub username:
   ```
   DOCKER_USERNAME="your-username"
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deploy.sh
   ```

3. Log in to Docker:
   ```bash
   docker login
   ```

4. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

## Usage

You can invoke the action in two ways:

### 1. Using an image URL

```bash
wsk -i action invoke python-image-classifier -r -p url "https://www.bestpets.co/wp-content/uploads/2017/08/e38767b2d4005b865e1854c265e9ab7e.jpg"
```

### 2. Using a base64-encoded image

```bash
# Encode a local image
BASE64_IMAGE=$(base64 -w 0 path/to/your/image.jpg)

# Invoke the action
wsk -i action invoke python-image-classifier -r -p image "$BASE64_IMAGE"
```

## Technical Details

- The action uses TensorFlow 2.4.0 and the pre-trained MobileNetV2 model
- The Docker image extends the official OpenWhisk Python action runtime
- Prediction results include the top 5 detected classes with confidence scores

## Notes

- The first invocation will be slow due to cold start and model loading
- Consider creating a dedicated invoker pool with higher resources for ML workloads
- Increase the memory limit if you encounter memory-related errors

## Troubleshooting

If you encounter issues:

1. Check that your Docker image was pushed successfully to DockerHub
2. Verify that your OpenWhisk installation is configured to run Docker actions
3. Check OpenWhisk activation logs for errors
4. Try increasing memory and timeout if the action fails due to resource constraints