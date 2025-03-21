

const tf = require('@tensorflow/tfjs');

function generateData(numSamples, numFeatures) {
  
  const features = tf.randomNormal([numSamples, numFeatures]);

  const trueWeights = tf.randomNormal([numFeatures, 1]);
  const trueBias = tf.scalar(Math.random() * 10);
  
  
  const yPerfect = tf.matMul(features, trueWeights).add(trueBias);
  const noise = tf.randomNormal([numSamples, 1], 0, 0.1);
  const labels = yPerfect.add(noise);
  
  return {
    features,
    labels,
    trueWeights,
    trueBias
  };

}


async function trainLinearRegression(features, labels, epochs) {
  
  const model = tf.sequential();
  

  model.add(tf.layers.dense({
    units: 1,
    inputShape: [features.shape[1]],
    activation: 'linear'
  }));
  

  model.compile({
    optimizer: tf.train.sgd(0.01),
    loss: 'meanSquaredError',
    metrics: ['mse']
  });
  

  const history = await model.fit(features, labels, {
    epochs: epochs,
    batchSize: 32,
    validationSplit: 0.2,
    verbose: 0
  });
  
  return {
    model,
    history: history.history
  };
}


function getCoefficients(model) {
  
  const weights = model.layers[0].getWeights()[0].arraySync();
  const bias = model.layers[0].getWeights()[1].arraySync()[0];
  
  return {
    weights,
    bias
  };
}

function evaluateModel(model, testFeatures, testLabels) {

  const predictions = model.predict(testFeatures);

  const mse = tf.metrics.meanSquaredError(testLabels, predictions).dataSync()[0];
  const mae = tf.metrics.meanAbsoluteError(testLabels, predictions).dataSync()[0];
  
  return {
    mse,
    mae
  };
}


async function main(params) {
  try {
    
    const numSamples = params.numSamples || 2000;
    const numFeatures = params.numFeatures || 12;
    const epochs = params.epochs || 3;
    
    
    const {features, labels, trueWeights, trueBias} = generateData(numSamples, numFeatures);
    
    
    const splitIdx = Math.floor(numSamples * 0.8);
    
    const trainFeatures = features.slice([0, 0], [splitIdx, numFeatures]);
    const trainLabels = labels.slice([0, 0], [splitIdx, 1]);
    
    const testFeatures = features.slice([splitIdx, 0], [numSamples - splitIdx, numFeatures]);
    const testLabels = labels.slice([splitIdx, 0], [numSamples - splitIdx, 1]);
    
    
    console.log(`Training linear regression model with ${numFeatures} features for ${epochs} epochs...`);
    const {model, history} = await trainLinearRegression(trainFeatures, trainLabels, epochs);
    
    
    const coefficients = getCoefficients(model);
    
    
    const trueCoefficients = {
      weights: trueWeights.arraySync(),
      bias: trueBias.arraySync()
    };
    
    
    const metrics = evaluateModel(model, testFeatures, testLabels);
    
    
    return {

      success: true,
      trainingHistory: history,
      evaluation: metrics,

      modelInfo: {
        numSamples,
        numFeatures,
        epochs
      },
      coefficients: coefficients,
      trueCoefficients: trueCoefficients
    };

  } catch (error) {

    return {
      success: false,
      error: error.message
    };

  }

}
module.exports.main = main;
