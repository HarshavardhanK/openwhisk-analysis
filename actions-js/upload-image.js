const { MongoClient } = require('mongodb');
const axios = require('axios');

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
    
    return {
      success: true,
      id: result.insertedId,
      message: `Image '${imageName}' uploaded successfully`,
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