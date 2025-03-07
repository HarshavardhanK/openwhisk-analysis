#\!/bin/bash
# Script to deploy the monitoring demo action

set -e

echo "===================================================="
echo "  Deploying OpenWhisk Monitoring Demo Action"
echo "===================================================="

# Check if wsk CLI is available
if \! command -v wsk &> /dev/null; then
    echo "Error: OpenWhisk CLI (wsk) not found."
    echo "Please install wsk CLI before deploying actions."
    exit 1
fi

# Check if the monitoring-demo.js file exists
if [ \! -f "./actions/monitoring-demo.js" ]; then
    echo "Error: monitoring-demo.js not found in ./actions directory."
    exit 1
fi

# Deploy the action
echo "Deploying monitoring-demo action..."
wsk -i action create monitoring-demo actions/monitoring-demo.js

# Verify the action was created
echo "Verifying action deployment..."
wsk -i action get monitoring-demo

# Invoke the action
echo -e "\nInvoking monitoring-demo action..."
wsk -i action invoke monitoring-demo --result

echo -e "\n===================================================="
echo "Monitoring demo action has been deployed and tested."
echo "You can invoke it again with:"
echo "wsk -i action invoke monitoring-demo --result"
echo "===================================================="
