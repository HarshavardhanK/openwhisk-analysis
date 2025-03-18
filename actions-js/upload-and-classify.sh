#!/bin/bash
# Script to upload an image and then trigger classification

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. Please install jq."; exit 1; }


if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <image_url> [image_name]"
    echo "Example: $0 https://example.com/image.jpg my-cat-image"
    exit 1
fi

IMAGE_URL="$1"
IMAGE_NAME="${2:-image_$(date +%s)}" 

echo "Uploading image from $IMAGE_URL as '$IMAGE_NAME'..."

#Upload the image using the upload-image action
UPLOAD_RESULT=$(wsk -i action invoke upload-image --result --param imageUrl "$IMAGE_URL" --param imageName "$IMAGE_NAME")

if [ $? -ne 0 ] || [ -z "$UPLOAD_RESULT" ]; then
    echo "Error: Failed to upload image."
    exit 1
fi

IMAGE_ID=$(echo "$UPLOAD_RESULT" | jq -r '.id')

if [ -z "$IMAGE_ID" ] || [ "$IMAGE_ID" = "null" ]; then
    echo "Error - Could not extract image ID from result."
    echo "Result was: $UPLOAD_RESULT"
    exit 1
fi

echo "Image uploaded successfully with ID: $IMAGE_ID"
echo "Triggering image classification..."

#Fire the trigger to classify the image
wsk -i trigger fire /whisk.system/image-uploaded --param imageId "$IMAGE_ID" --param imageName "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to fire the classification trigger."
    exit 1
fi

echo "Classification process started."
echo "Waiting for classification results..."

#Wait a moment for the classification to complete
sleep 3

echo "Recent mobilenet-mongo activations:"
wsk -i activation list --limit 3 mobilenet-mongo

echo ""
echo "To view classification results, run:"
echo "wsk -i activation result <activation-id>"