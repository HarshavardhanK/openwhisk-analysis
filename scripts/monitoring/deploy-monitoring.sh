#!/bin/bash
# Main script to deploy both Prometheus and Grafana for OpenWhisk monitoring

set -e

echo "===================================================="
echo "  OpenWhisk Monitoring Deployment"
echo "===================================================="

# Check for prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl and try again."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "Error: helm not found. Please install helm and try again."
    exit 1
fi

if ! command -v minikube &> /dev/null; then
    echo "Error: minikube not found. Please install minikube and try again."
    exit 1
fi

if ! minikube status 2>/dev/null | grep -q "host: Running"; then
    echo "Error: Minikube is not running. Please start Minikube first."
    exit 1
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
NAMESPACE=${1:-openwhisk}

if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "Error: Namespace '$NAMESPACE' does not exist."
    echo "Please deploy OpenWhisk before adding monitoring, or specify a different namespace."
    exit 1
fi

echo "Using Minikube IP: $MINIKUBE_IP"
echo "Using namespace: $NAMESPACE"

chmod +x ./scripts/monitoring/deploy-prometheus.sh 
chmod +x ./scripts/monitoring/deploy-grafana.sh

echo "Step 1: Deploying Prometheus..."
./scripts/monitoring/deploy-prometheus.sh "$MINIKUBE_IP" "$NAMESPACE"


echo "Step 2: Deploying Grafana..."
./scripts/monitoring/deploy-grafana.sh "$MINIKUBE_IP" "$NAMESPACE" "prometheus-server"

if [ -f "./scripts/monitoring/import-dashboard.sh" ]; then
    echo "Step 3: Importing OpenWhisk dashboard into Grafana..."
    ./scripts/monitoring/import-dashboard.sh "$MINIKUBE_IP" "$NAMESPACE"
else
    echo "Step 3: Skipping dashboard import (import-dashboard.sh not found)"
    echo "You can manually import dashboards through the Grafana UI"
fi

echo "===================================================="
echo "OpenWhisk Monitoring Deployment Summary:"
echo "===================================================="
echo "Prometheus URL: http://$MINIKUBE_IP:30900"
echo "Grafana URL: http://$MINIKUBE_IP:30300"
echo "Grafana Username: admin"
GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana Password: $GRAFANA_PASSWORD"
echo ""
echo "OpenWhisk dashboard has been imported to Grafana."
echo ""
echo "Note: It may take a few minutes for all metrics to start appearing."
echo "===================================================="