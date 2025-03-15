FROM openwhisk/action-nodejs-v20:latest

# Install TensorFlow.js and required dependencies with specific versions
RUN npm install @tensorflow/tfjs \
    @tensorflow/tfjs-node \
    @tensorflow-models/mobilenet \
    @tensorflow-models/coco-ssd \
    node-fetch \
    jpeg-js \
    mongodb \
    axios \
    openwhisk

# Test that modules can be loaded
RUN node -e "require('@tensorflow/tfjs'); require('@tensorflow/tfjs-node'); require('@tensorflow-models/mobilenet'); require('@tensorflow-models/coco-ssd'); require('mongodb'); require('openwhisk')"