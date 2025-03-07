#!/bin/bash
# AUTHOR: HARSHAVARDHAN K
# Script to check the status of OpenWhisk deployment on Kubernetes and verify functionality

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Function to check OpenWhisk deployment status
check_openwhisk_deployment() {
  echo "Checking OpenWhisk deployment status in namespace 'openwhisk'..."
  
  # Check if the namespace exists
  if ! kubectl get namespace openwhisk &>/dev/null; then
    echo -e "${RED}Error: The 'openwhisk' namespace does not exist.${NC}"
    echo "Please deploy OpenWhisk first."
    exit 1
  fi

  # Check if the Helm release exists
  if ! helm list -n openwhisk | grep -q "owdev"; then
    echo -e "${RED}Error: No OpenWhisk release named 'owdev' found in namespace 'openwhisk'.${NC}"
    echo "Please deploy OpenWhisk first."
    exit 1
  fi

  echo -e "${YELLOW}Checking pod status...${NC}"
  
  # Get all pods and their statuses
  echo "=== Pod Status ==="
  kubectl get pods -n openwhisk
  
  # Count pods not in Running or Completed state
  NOT_READY=$(kubectl get pods -n openwhisk -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | grep -v "Running" | grep -v "Completed" | wc -l)
  
  if [ "$NOT_READY" -gt 0 ]; then
    echo -e "\n${RED}Warning: $NOT_READY pods are not in Running/Completed state.${NC}"
    
    # Show details of problematic pods
    echo -e "\n${YELLOW}Problematic Pods:${NC}"
    kubectl get pods -n openwhisk | grep -v "Running" | grep -v "Completed"
    
    echo -e "\n${YELLOW}Checking events for potential issues:${NC}"
    kubectl get events -n openwhisk --sort-by='.lastTimestamp' | tail -10
  else
    echo -e "\n${GREEN}All pods are in Running or Completed state.${NC}"
  fi

  # Check if install-packages job completed
  if kubectl get job -n openwhisk | grep -q "install-packages"; then
    INSTALL_PACKAGES_STATUS=$(kubectl get job -n openwhisk | grep install-packages | awk '{print $2}')
    if [[ "$INSTALL_PACKAGES_STATUS" == "1/1" ]]; then
      echo -e "${GREEN}✓ Install packages job completed successfully.${NC}"
    else
      echo -e "${RED}✗ Install packages job has not completed (status: $INSTALL_PACKAGES_STATUS).${NC}"
    fi
  else
    echo -e "${RED}✗ Install packages job not found.${NC}"
  fi
  
  # Try to get the OpenWhisk API endpoint
  API_HOST=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):31001
  
  echo -e "\n${YELLOW}Testing OpenWhisk API accessibility:${NC}"
  if curl -k -s -f -m 5 https://$API_HOST/api/v1 &>/dev/null; then
    echo -e "${GREEN}✓ OpenWhisk API is accessible at https://$API_HOST/api/v1${NC}"
  else
    echo -e "${RED}✗ Cannot access OpenWhisk API at https://$API_HOST/api/v1${NC}"
  fi
  
  # Verify wsk CLI configuration
  echo -e "\n${YELLOW}Checking wsk CLI configuration:${NC}"
  if command -v wsk &>/dev/null; then
    WSK_APIHOST=$(wsk property get --apihost | awk '{print $3}')
    echo "Current wsk CLI configuration:"
    wsk property get
    
    if [ "$WSK_APIHOST" != "$API_HOST" ]; then
      echo -e "${YELLOW}Warning: wsk CLI is configured to use $WSK_APIHOST, but the detected API host is $API_HOST${NC}"
      echo "Run the following command to update it:"
      echo "wsk property set --apihost $API_HOST"
    fi
    
    echo -e "\n${YELLOW}Testing a simple action invocation:${NC}"
    echo "wsk -i action invoke /whisk.system/utils/echo -p message hello --result"
    
    if wsk -i action invoke /whisk.system/utils/echo -p message hello --result 2>/dev/null | grep -q "hello"; then
      echo -e "${GREEN}✓ Successfully invoked test action!${NC}"
      echo -e "\n${GREEN}=== OpenWhisk is correctly deployed and functional ===${NC}"
    else
      echo -e "${RED}✗ Failed to invoke test action.${NC}"
      echo "Check authentication settings with: wsk property get --auth"
    fi
  else
    echo -e "${YELLOW}wsk CLI not found. Install the OpenWhisk CLI to interact with your deployment.${NC}"
    echo "Visit: https://github.com/apache/openwhisk-cli/releases"
  fi
}

# Execute the check
check_openwhisk_deployment

echo -e "\n${YELLOW}Resource Usage:${NC}"
echo "=== Node Resource Usage ==="
kubectl top nodes

echo -e "\n=== Pods Resource Usage ==="
kubectl top pods -n openwhisk