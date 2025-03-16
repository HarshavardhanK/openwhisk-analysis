const tf = require('@tensorflow/tfjs-node');
const mobilenet = require('@tensorflow-models/mobilenet');

const { MongoClient } = require('mongodb');

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

  const time = (diff[0] * 1e9 + diff[1]) / 1e6; //convert to ms
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


async function processBase64Image(base64Image, targetSize = 224) {

  startTimer('imageProcessing');
  
  try {

    console.log('Processing base64 image');
    
    const buffer = Buffer.from(base64Image, 'base64');
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
    throw new Error(`Error processing base64 image: ${error.message}`);
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

//Create response object
function createResponse(predictions, imageInfo) {

  return {

    predictions,
    imageInfo,

    performance: {
      timings: metrics.stages,
      memory: metrics.memory
    },

    message: "Classification complete"

  };

}

//Fetch the most recent image from MongoDB
async function fetchLatestImageFromMongo() {
  startTimer('fetchMongo');
  
  const MONGODB_URI = "mongodb+srv://tsarshah:Harsha$1199@fun.6fkvq.mongodb.net/?retryWrites=true&w=majority&appName=fun";
  
  try {
    
    const client = new MongoClient(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true });
    await client.connect();
    
    console.log('Connected to MongoDB Atlas');
    
    //Access the database and collection
    const database = client.db('images');
    const collection = database.collection('imageCollection');
    
    //Find the most recent image
    const latestImage = await collection.find()
      .sort({ uploadDate: -1 })
      .limit(1)
      .toArray();
    
    if (latestImage.length === 0) {
      throw new Error('No images found in the database');
    }
    
    console.log(`Retrieved image '${latestImage[0].name}' from MongoDB`);
    
    await client.close();
    
    endTimer('fetchMongo');
    
    return {

      imageData: latestImage[0].data,

      imageInfo: {

        name: latestImage[0].name,
        contentType: latestImage[0].contentType,
        uploadDate: latestImage[0].uploadDate,
        source: latestImage[0].source,
        id: latestImage[0]._id

      }
    };
    
  } catch (error) {
    throw new Error(`Error fetching image from MongoDB: ${error.message}`);
  }
}

//OpenWhisk action entry point

async function main(params) {

  startTimer('total');
  trackMemory('start');
  
  let imageTensor = null;
  
  try {
    console.log('Starting MongoDB image classification...');
    
    
    const imageId = params.imageId || null;
    
    //MobileNet expects 224x224
    const targetSize = params.targetSize || 224;
    
    //Fetch the image from MongoDB
    const { imageData, imageInfo } = await fetchLatestImageFromMongo();
    
   
    imageTensor = await processBase64Image(imageData, targetSize);
    console.log('Image processed, shape:', imageTensor.shape);
    
   
    const model = await loadModel();
    
    //Run classification
    console.log('Running classification...');
    const predictions = await classifyImage(model, imageTensor);
    console.log('Classification complete:', predictions);
    
    
    imageTensor.dispose();
    
    
    endTimer('total');
    trackMemory('end');
    
    console.log('Classification finished successfully');
    
    return createResponse(predictions, imageInfo);
    
  } catch (error) {
    console.error('Error in classification:', error.message);
    console.error('Stack trace:', error.stack);
    
    // Clean up tensor memory
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

module.exports.main = main;