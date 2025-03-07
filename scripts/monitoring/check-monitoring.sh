#!/bin/bash
# Script to check Prometheus and Grafana deployment status

set -e

# Get the Minikube IP
MINIKUBE_IP=${1:-$(minikube ip)}
NAMESPACE=${2:-openwhisk}

echo "===================================================="
echo "  OpenWhisk Monitoring Status Check"
echo "===================================================="
echo "Using Minikube IP: $MINIKUBE_IP"
echo "Using namespace: $NAMESPACE"

# Check if Prometheus is running
echo -e "\n### Checking Prometheus Status ###"
if kubectl get deployment prometheus-server -n $NAMESPACE &>/dev/null; then
    echo "✅ Prometheus server deployment found"
    
    # Check Prometheus pods
    PROMETHEUS_PODS=$(kubectl get pods -n $NAMESPACE -l "app=prometheus,component=server" -o jsonpath='{.items[*].status.phase}')
    if [[ "$PROMETHEUS_PODS" == "Running" ]]; then
        echo "✅ Prometheus server pod is running"
    else
        echo "❌ Prometheus server pod is not running: $PROMETHEUS_PODS"
    fi
    
    # Check Prometheus service
    if kubectl get service prometheus-server -n $NAMESPACE &>/dev/null; then
        echo "✅ Prometheus server service found"
        
        # Try to access Prometheus API
        if curl -s --connect-timeout 5 http://$MINIKUBE_IP:30900/api/v1/query?query=up &>/dev/null; then
            echo "✅ Prometheus API is accessible at http://$MINIKUBE_IP:30900"
            
            # Get some sample metrics
            UP_STATUS=$(curl -s http://$MINIKUBE_IP:30900/api/v1/query?query=up | jq -r '.data.result[] | .metric.job + ": " + (.value[1] | tostring)')
            echo -e "\nSample Prometheus metrics:"
            echo "Up status of monitored targets:"
            echo "$UP_STATUS"
        else
            echo "❌ Prometheus API is not accessible at http://$MINIKUBE_IP:30900"
        fi
    else
        echo "❌ Prometheus server service not found"
    fi
else
    echo "❌ Prometheus server deployment not found in namespace $NAMESPACE"
fi

# Check if Grafana is running
echo -e "\n### Checking Grafana Status ###"
if kubectl get deployment grafana -n $NAMESPACE &>/dev/null; then
    echo "✅ Grafana deployment found"
    
    # Check Grafana pods
    GRAFANA_PODS=$(kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/name=grafana" -o jsonpath='{.items[*].status.phase}')
    if [[ "$GRAFANA_PODS" == "Running" ]]; then
        echo "✅ Grafana pod is running"
    else
        echo "❌ Grafana pod is not running: $GRAFANA_PODS"
    fi
    
    # Check Grafana service
    if kubectl get service grafana -n $NAMESPACE &>/dev/null; then
        echo "✅ Grafana service found"
        
        # Try to access Grafana
        if curl -s --connect-timeout 5 http://$MINIKUBE_IP:30300/api/health &>/dev/null; then
            echo "✅ Grafana is accessible at http://$MINIKUBE_IP:30300"
            
            # Get Grafana health status
            HEALTH_STATUS=$(curl -s http://$MINIKUBE_IP:30300/api/health | jq -r '.database')
            echo -e "\nGrafana health status:"
            echo "Database: $HEALTH_STATUS"
            
            # Get Grafana admin password
            GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
            echo -e "\nGrafana access information:"
            echo "URL: http://$MINIKUBE_IP:30300"
            echo "Username: admin"
            echo "Password: $GRAFANA_PASSWORD"
        else
            echo "❌ Grafana is not accessible at http://$MINIKUBE_IP:30300"
        fi
    else
        echo "❌ Grafana service not found"
    fi
else
    echo "❌ Grafana deployment not found in namespace $NAMESPACE"
fi

# Display instructions for deploying the demo action
echo -e "\n### Monitoring Demo Action ###"
echo "To deploy and run the monitoring demo action, execute:"
echo "wsk -i action create monitoring-demo actions/monitoring-demo.js"
echo "wsk -i action invoke monitoring-demo --result"

echo -e "\n===================================================="
echo "Tip: To view metrics in Grafana, visit http://$MINIKUBE_IP:30300"
echo "     and login with the credentials shown above."
echo "===================================================="