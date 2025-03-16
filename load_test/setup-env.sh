#!/bin/bash

# Get OpenWhisk auth from current configuration
OPENWHISK_AUTH=$(wsk property get --auth | awk '{print $3}')

# Export as environment variables - make sure to use echo -n to avoid newlines
export OPENWHISK_AUTH
export OPENWHISK_AUTH_ENCODED=$(echo -n "$OPENWHISK_AUTH" | base64 | tr -d '\n')

echo "Environment variables set:"
echo "OPENWHISK_AUTH=$OPENWHISK_AUTH"
echo "OPENWHISK_AUTH_ENCODED=$OPENWHISK_AUTH_ENCODED"
echo ""
echo "Run your Artillery test with:"
echo "artillery run --insecure openwhisk-test.yml"