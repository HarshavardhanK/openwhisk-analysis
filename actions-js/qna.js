/**
 * OpenWhisk action for Question and Answer model
 * Simple implementation without TensorFlow for debugging
 */

// Simple version without TensorFlow for debugging
function main(params) {
  try {
    // Validate input parameters
    if (!params.question) {
      return { error: "Missing required parameter 'question'" };
    }
    
    if (!params.passage) {
      return { error: "Missing required parameter 'passage'" };
    }
    
    // For testing purposes, return a mock response
    // This avoids TensorFlow loading issues in the container
    const mockText = "Sundar Pichai";
    const startIndex = params.passage.indexOf(mockText);
    
    return {
      answers: [
        {
          text: mockText,
          startIndex: startIndex >= 0 ? startIndex : 0,
          endIndex: startIndex >= 0 ? startIndex + mockText.length : mockText.length,
          score: 0.95
        }
      ],
      debug: {
        question: params.question,
        passageLength: params.passage.length
      }
    };
  } catch (error) {
    return {
      error: `Error processing request: ${error.message}`,
      stack: error.stack
    };
  }
}

// Export the main function for OpenWhisk
module.exports.main = main;