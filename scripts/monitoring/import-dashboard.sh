#!/bin/bash
# Script to import OpenWhisk dashboard into Grafana

MINIKUBE_IP=${1:-$(minikube ip)}
NAMESPACE=${2:-openwhisk}
GRAFANA_PASSWORD=${3:-$(kubectl get secret -n $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)}

GRAFANA_URL="http://$MINIKUBE_IP:30300"

echo "Importing OpenWhisk dashboard into Grafana..."
# Import the dashboard using Grafana API
curl -X POST -H "Content-Type: application/json" -H "Authorization: Basic $(echo -n admin:$GRAFANA_PASSWORD | base64)" "$GRAFANA_URL/api/dashboards/db" -d @- << EOFCURL
{
  "dashboard": $(cat openwhisk-dashboard.json),
  "overwrite": true
}
EOFCURL

echo -e "\nDashboard import completed!"
