#!/bin/bash

#Script to run all load tests for OpenWhisk actions

echo "Running mobilenet-mongo test..."
artillery run --insecure openwhisk-test.yml | tee mobilenet-mongo-results.txt

echo "Running lin_reg test..."
artillery run --insecure lin_reg.yml | tee lin_reg-results.txt

echo "Running mobilenet-simple test..."
artillery run --insecure mobilenet-simple.yml | tee mobilenet-simple-results.txt

echo "All tests completed. Results saved to *-results.txt files."