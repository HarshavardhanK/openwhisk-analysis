#!/bin/bash
set -e

echo "===== OpenWhisk Cleanup Script ====="
echo "This script will remove all OpenWhisk components from your Kubernetes cluster."
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

# Uninstall OpenWhisk Helm release
echo "Uninstalling OpenWhisk Helm release..."
helm uninstall owdev -n openwhisk 2>/dev/null || echo "No OpenWhisk Helm release found."

# Delete the OpenWhisk namespace and all resources in it
echo "Deleting OpenWhisk namespace and all its resources..."
kubectl delete namespace openwhisk --wait=false 2>/dev/null || echo "OpenWhisk namespace not found."

# Delete any persistent volumes that might have been left behind
echo "Checking for persistent volumes to clean up..."
PVS=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="openwhisk")].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PVS" ]; then
  echo "Deleting persistent volumes associated with OpenWhisk..."
  for pv in $PVS; do
    kubectl delete pv $pv --wait=false
    echo "Deleted PV: $pv"
  done
else
  echo "No OpenWhisk persistent volumes found."
fi

# Force finalization of the namespace if it's stuck
echo "Checking if namespace is stuck in Terminating state..."
NS_STATUS=$(kubectl get namespace openwhisk -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
if [ "$NS_STATUS" == "Terminating" ]; then
  echo "Namespace is stuck in Terminating state. Forcing removal..."
  kubectl get namespace openwhisk -o json | \
    jq '.spec.finalizers = []' | \
    kubectl replace --raw "/api/v1/namespaces/openwhisk/finalize" -f -
fi

echo "
===== Cleanup Complete =====

All OpenWhisk components have been removed or are being removed.
If you want to verify, check with:
  kubectl get all -n openwhisk

To completely reset Minikube (optional):
  minikube stop
  minikube delete
  minikube start --memory=4096 --cpus=2
"