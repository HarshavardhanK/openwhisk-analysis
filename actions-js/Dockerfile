FROM openwhisk/action-nodejs-v20:latest

# Install TensorFlow.js and required dependencies with specific versions
RUN npm install @tensorflow/tfjs \
    @tensorflow/tfjs-node \
    @tensorflow-models/mobilenet \
    @tensorflow-models/coco-ssd \
    @tensorflow-models/qna \
    @tensorflow/tfjs-converter \
    @tensorflow/tfjs-core \
    node-fetch \
    jpeg-js \
    mongodb \
    axios \
    openwhisk

# Test that modules can be loaded
RUN node -e "require('@tensorflow/tfjs'); require('@tensorflow/tfjs-node'); require('@tensorflow/tfjs-converter'); require('@tensorflow/tfjs-core'); require('@tensorflow-models/mobilenet'); require('@tensorflow-models/coco-ssd'); require('@tensorflow-models/qna'); require('mongodb'); require('openwhisk')"