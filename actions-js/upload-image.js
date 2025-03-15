const { MongoClient } = require('mongodb');
const axios = require('axios'); 
const openwhisk = require('openwhisk');

/**
 * Uploads an image from a URL to MongoDB Atlas
 * 
 * @param {Object} params - The parameters object
 * @param {string} params.imageUrl - URL of the image to upload
 * @param {string} params.imageName - Name to store the image with (optional)
 * @returns {Object} - Information about the uploaded image
 */

async function main(params) {
  
  const MONGODB_URI = "mongodb+srv://tsarshah:Harsha$1199@fun.6fkvq.mongodb.net/?retryWrites=true&w=majority&appName=fun";
  
  if (!params.imageUrl) {
    return { error: 'Missing required parameter: imageUrl' };
  }
  
  const imageName = params.imageName || `image_${Date.now()}`;
  
  try {
    //Fetch the image from the URL

    console.log(`Fetching image from: ${params.imageUrl}`);

    const response = await axios({

      method: 'get',
      url: params.imageUrl,
      responseType: 'arraybuffer'

    });
    
    if (response.status !== 200) {
      throw new Error(`Failed to fetch image: ${response.statusText}`);
    }
    
    //Get image data as Buffer
    const buffer = Buffer.from(response.data);
    
    //Convert image to base64 string for storage
    const base64Image = buffer.toString('base64');
    
    //Connect to MongoDB
    const client = new MongoClient(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true });
    await client.connect();
    
    console.log('Connected to MongoDB Atlas');
    
    //Access the database and collection
    const database = client.db('images');
    const collection = database.collection('imageCollection');
    
    //Create document with image data

    const imageDocument = {

      name: imageName,
      contentType: response.headers['content-type'],
      data: base64Image,

      uploadDate: new Date(),
      source: params.imageUrl

    };
    
    
    const result = await collection.insertOne(imageDocument);
    console.log(`Image '${imageName}' uploaded to MongoDB Atlas`);
    
    
    await client.close();
    
    //Fire the image-uploaded trigger
    try {
      console.log('Trying to fire image-uploaded trigger');
      
      
      console.log('OpenWhisk Environment:', {
        apihost: process.env.__OW_API_HOST,
        api_key: process.env.__OW_API_KEY ? 'Exists' : 'Missing',
        namespace: process.env.__OW_NAMESPACE,
        ignore_certs: process.env.__OW_IGNORE_CERTS || 'Not set'
      });
      
      //Initialize OpenWhisk client with explicit options
      const options = {
        apihost: process.env.__OW_API_HOST || '130.127.133.47:31001', 
        api_key: process.env.__OW_API_KEY,
        namespace: process.env.__OW_NAMESPACE || 'whisk.system',
        ignore_certs: true
      };
      
      console.log('Using OpenWhisk options:', {
        apihost: options.apihost,
        api_key: options.api_key ? 'Exists' : 'Missing',
        namespace: options.namespace
      });
      
      const ow = openwhisk(options);
      
      //Fire the trigger with image information
      console.log('Invoking trigger image-uploaded');

      const triggerResult = await ow.triggers.invoke({
        name: 'image-uploaded',

        params: {


          imageId: result.insertedId.toString(),
          imageName: imageName,
          up
          loadTime: new Date().toISOString()

        }
        
      });
      
      console.log('Successfully fired image-uploaded trigger:', triggerResult);

    } catch (triggerError) {

      console.error('Error firing trigger:', triggerError.message);
      console.error('Trigger error stack:', triggerError.stack);
      //Continue execution even if trigger fails - don't throw
    }
    
    return {

      success: true,
      id: result.insertedId,
      message: `Image '${imageName}' uploaded successfully and classification triggered`,
      contentType: response.headers['content-type'],
      size: buffer.length

    };


  } catch (error) {

    console.error('Error uploading image:', error.message);
    console.error('Stack trace:', error.stack);
    
    return {

      success: false,
      error: error.message,
      stack: error.stack

    };


  }
}

exports.main = main;