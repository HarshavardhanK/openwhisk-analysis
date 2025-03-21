#!/bin/bash

docker build -t lin_reg_action -f Dockerfile.lin_reg .

#Deploy OpenWhisk action
wsk -i action update /whisk.system/lin_reg lin_reg.js --docker lin_reg_action

echo "Deployment completed."