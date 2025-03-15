const tf = require('@tensorflow/tfjs-node');
const mobilenet = require('@tensorflow-models/mobilenet');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

//Performance tracking utilities
const startTimes = {};
const metrics = {
  stages: {},
  memory: {}
};

function startTimer(label) {
  startTimes[label] = process.hrtime();
}

function endTimer(label) {

  const diff = process.hrtime(startTimes[label]);
  const time = (diff[0] * 1e9 + diff[1]) / 1e6; // convert to ms
  metrics.stages[label] = `${time.toFixed(2)}ms`;
  return time;
  
}

function trackMemory(label) {
  const used = process.memoryUsage();

  metrics.memory[label] = {

    rss: `${Math.round(used.rss / 1024 / 1024 * 100) / 100}MB`,
    heapTotal: `${Math.round(used.heapTotal / 1024 / 1024 * 100) / 100}MB`,
    heapUsed: `${Math.round(used.heapUsed / 1024 / 1024 * 100) / 100}MB`,
    external: `${Math.round(used.external / 1024 / 1024 * 100) / 100}MB`,

  };
}

let cachedModel = null;

async function loadModel() {

  startTimer('loadModel');
  
  try {

    if (!cachedModel) {

      console.log('Loading MobileNet model for the first time');
      cachedModel = await mobilenet.load({
        version: 2,
        alpha: 1.0

      });
      console.log('Model loaded successfully');
    } else {
      console.log('Using cached model');
    }
    
    endTimer('loadModel');
    trackMemory('afterLoadModel');

    return cachedModel;
  } catch (error) {
    throw new Error(`Error loading model: ${error.message}`);
  }
}

//Load and preprocess image
async function loadAndProcessImage(imagePath, targetSize = 224) {
  startTimer('imageProcessing');
  
  try {
    console.log(`Loading image from: ${imagePath}`);
    
    const imageBuffer = fs.readFileSync(imagePath);
    const tfImage = tf.node.decodeImage(imageBuffer, 3);
    console.log(`Original image shape: ${tfImage.shape}`);
  
    const resizedImage = tf.image.resizeBilinear(tfImage, [targetSize, targetSize]);
    console.log(`Resized image shape: ${resizedImage.shape}`);
    
    //Clean up
    tfImage.dispose();
    
    endTimer('imageProcessing');
    trackMemory('afterImageProcessing');
    
    return resizedImage;

  } catch (error) {
    throw new Error(`Error processing image: ${error.message}`);
  }
}

//Image Classification
async function classifyImage(model, tensor) {
  startTimer('classify');
  
  try {
    //inference
    const predictions = await model.classify(tensor);
    
    endTimer('classify');
    trackMemory('afterClassify');
    
    return predictions;
  } catch (error) {
    throw new Error(`Error classifying image: ${error.message}`);
  }
}

//response object
function createResponse(predictions) {
  return {
    predictions,
    performance: {
      timings: metrics.stages,
      memory: metrics.memory
    },
    message: "Classification complete"
  };
}

//Fetch and process image from URL
async function fetchAndProcessImage(imageUrl, targetSize = 224) {
  startTimer('imageProcessing');
  
  try {
    console.log(`Fetching image from: ${imageUrl}`);
    
    const response = await axios({
      method: 'get',
      url: imageUrl,
      responseType: 'arraybuffer'
    });
    
    if (response.status !== 200) {
      throw new Error(`Failed to fetch image: ${response.statusText}`);
    }
    
    const buffer = Buffer.from(response.data);
    
    const tfImage = tf.node.decodeImage(buffer, 3);
    console.log(`Original image shape: ${tfImage.shape}`);
    
    const resizedImage = tf.image.resizeBilinear(tfImage, [targetSize, targetSize]);
    console.log(`Resized image shape: ${resizedImage.shape}`);
    
    //Clean up
    tfImage.dispose();
    
    endTimer('imageProcessing');
    trackMemory('afterImageProcessing');
    
    return resizedImage;
  } catch (error) {
    throw new Error(`Error processing image URL: ${error.message}`);
  }
}

//OpenWhisk action entry point
async function main(params) {
  startTimer('total');
  trackMemory('start');
  
  let imageTensor = null;
  
  try {
    console.log('Starting image classification...');
    
    //check if image path, URL, or base64 input is provided
    if (!params.imagePath && !params.imageBase64 && !params.imageUrl) {
      throw new Error('Missing required parameter: either imagePath, imageBase64, or imageUrl must be provided');
    }
    
    //(MobileNet expects 224x224)
    const targetSize = params.targetSize || 224;
    
    if (params.imagePath) {
      
      imageTensor = await loadAndProcessImage(params.imagePath, targetSize);

    } else if (params.imageUrl) {

      //Fetch and process image from URL
      imageTensor = await fetchAndProcessImage(params.imageUrl, targetSize);

    } else if (params.imageBase64) {

      //Decode base64 image
      startTimer('imageProcessing');
      
      const buffer = Buffer.from(params.imageBase64, 'base64');
      const tfImage = tf.node.decodeImage(buffer, 3);
      imageTensor = tf.image.resizeBilinear(tfImage, [targetSize, targetSize]);
      tfImage.dispose();
      
      endTimer('imageProcessing');
      trackMemory('afterImageProcessing');
    }
    
    console.log('Image processed, shape:', imageTensor.shape);
    
    // Load model
    const model = await loadModel();
    
    //classification

    console.log('Running classification...');

    const predictions = await classifyImage(model, imageTensor);
    console.log('Classification complete:', predictions);
    
    //Clean up tensor memory
    imageTensor.dispose();
    
    //Finalize metrics
    endTimer('total');
    trackMemory('end');
    
    console.log('Classification finished successfully');
    
    return createResponse(predictions);

  } catch (error) {

    console.error('Error in classification:', error.message);
    console.error('Stack trace:', error.stack);
    
    //Clean up tensor memory
    if (imageTensor) {
      imageTensor.dispose();
    }
    
    endTimer('total');
    trackMemory('error');
    
    return {
      error: error.message,
      stack: error.stack,
      performance: {
        timings: metrics.stages,
        memory: metrics.memory
      }
    };
  }
}

//Export main function for OpenWhisk
module.exports.main = main;