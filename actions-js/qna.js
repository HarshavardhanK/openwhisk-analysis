/**
 * OpenWhisk action for Question and Answer model using TensorFlow.js
 */

const tf = require('@tensorflow/tfjs-node');
const qna = require('@tensorflow-models/qna');

let modelInstance = null;

async function loadModel() {
  if (!modelInstance) {
    console.log('Loading QnA model...');
    modelInstance = await qna.load();
    console.log('Model loaded successfully');
  }
  return modelInstance;
}

async function main(params) {
  try {
    //Validate input parameters
    if (!params.question) {
      return { error: "Missing required parameter 'question'" };
    }
    
    if (!params.passage) {
      return { error: "Missing required parameter 'passage'" };
    }
    
    const model = await loadModel();
    
    console.log(`Processing question: "${params.question}"`);
    console.log(`Passage length: ${params.passage.length} characters`);
    
    const answers = await model.findAnswers(params.question, params.passage);
    
    if (!answers || answers.length === 0) {
      return {
        answers: [],
        message: "No answers found for the given question and passage",
        debug: {
          question: params.question,
          passageLength: params.passage.length
        }
      };
    }
    
    return {

      answers: answers.map(answer => ({

        text: answer.text,
        startIndex: answer.startIndex,
        endIndex: answer.endIndex,

        score: answer.score

      })),

      debug: {

        question: params.question,
        passageLength: params.passage.length,
        numAnswers: answers.length

      }

    };

  } catch (error) {

    console.error('Error in QnA processing:', error);

    return {
        
      error: `Error processing request: ${error.message}`,
      stack: error.stack
    };

  }
}

//Export the main function for OpenWhisk
module.exports.main = main;