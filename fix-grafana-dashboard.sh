#!/bin/bash
# ====================================================================
# OpenWhisk Grafana Dashboard Fix Script
# ====================================================================
#
# This script resolves issues with missing Grafana dashboards in an
# OpenWhisk deployment. It handles:
#
# 1. Manual dashboard import via Grafana API
# 2. Verification of Prometheus data sources
# 3. Confirmation of metric collection
#
# The script addresses several common issues:
#
# - Port forwarding requirements
# - Dashboard import failures 
# - Shell escaping issues with curl commands
# - Prometheus data source configuration
#
# REQUIREMENTS:
# - kubectl installed and configured for your cluster
# - curl and jq installed
# - Active port forwarding to Grafana (port 3000)
# - Active port forwarding to Prometheus (port 9090) (optional but helpful)
#
# PORT FORWARDING EXPLANATION:
# Each port forwarding command runs in its own terminal session:
#
# Terminal 1: kubectl port-forward svc/owdev-nginx 31001:443 -n openwhisk
# Terminal 2: kubectl port-forward svc/grafana 3000:80 -n openwhisk
# Terminal 3: kubectl port-forward svc/prometheus-server 9090:80 -n openwhisk
#
# You can't combine these commands - each one occupies its own process
# and keeps that terminal session busy until terminated.
#
# ====================================================================

set -e  # Exit on any error

echo "======================================================================"
echo "OpenWhisk Grafana Dashboard Fix Script"
echo "======================================================================"

# Configuration
DASHBOARD_JSON="/Users/harshavardhank/Desktop/Code/openwhisk-project/configs/monitoring/openwhisk-dashboard.json"
NAMESPACE="openwhisk"
GRAFANA_URL="http://localhost:3000"
PROMETHEUS_URL="http://localhost:9090"

# Check if dashboard JSON exists
if [ ! -f "$DASHBOARD_JSON" ]; then
    echo "ERROR: Dashboard JSON file not found at $DASHBOARD_JSON"
    exit 1
fi

# Step 1: Verify Grafana port forwarding
echo "Step 1: Verifying Grafana port forwarding..."
if ! curl -s "$GRAFANA_URL/api/health" > /dev/null; then
    echo "ERROR: Cannot connect to Grafana at $GRAFANA_URL"
    echo "Make sure you have port forwarding active in another terminal with:"
    echo "  kubectl port-forward svc/grafana 3000:80 -n $NAMESPACE"
    exit 1
fi
echo "SUCCESS: Grafana is accessible"

# Step 2: Get Grafana credentials
echo "Step 2: Getting Grafana admin credentials..."
GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
if [ -z "$GRAFANA_PASSWORD" ]; then
    echo "ERROR: Could not retrieve Grafana password"
    exit 1
fi
echo "SUCCESS: Retrieved Grafana admin password"

# Step 3: Check Prometheus data source configuration
echo "Step 3: Checking Prometheus data source in Grafana..."
DS_RESPONSE=$(curl -s -H "Authorization: Basic $(echo -n admin:$GRAFANA_PASSWORD | base64)" "$GRAFANA_URL/api/datasources")
if ! echo "$DS_RESPONSE" | grep -q "Prometheus"; then
    echo "ERROR: Prometheus data source not configured in Grafana"
    exit 1
fi
echo "SUCCESS: Prometheus data source is configured in Grafana"

# Step 4: Import dashboard
echo "Step 4: Importing OpenWhisk dashboard to Grafana..."

# Note: We need to properly escape the JSON for the curl command
# This is a common issue that causes dashboard imports to fail
IMPORT_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n admin:$GRAFANA_PASSWORD | base64)" \
  "$GRAFANA_URL/api/dashboards/db" \
  -d "{\"dashboard\": $(cat $DASHBOARD_JSON), \"overwrite\": true}")

if ! echo "$IMPORT_RESPONSE" | grep -q "success"; then
    echo "ERROR: Dashboard import failed"
    echo "Response: $IMPORT_RESPONSE"
    exit 1
fi
echo "SUCCESS: Dashboard imported successfully!"

# Step 5: Verify dashboard is in Grafana
echo "Step 5: Verifying dashboard in Grafana..."
DASH_RESPONSE=$(curl -s -H "Authorization: Basic $(echo -n admin:$GRAFANA_PASSWORD | base64)" "$GRAFANA_URL/api/search?query=OpenWhisk")
if ! echo "$DASH_RESPONSE" | grep -q "OpenWhisk Dashboard"; then
    echo "ERROR: Dashboard not found after import"
    exit 1
fi
echo "SUCCESS: Dashboard exists in Grafana"

# Step 6: Check if metrics are being collected (optional)
echo "Step 6: Checking Prometheus metrics collection (optional)..."
if curl -s "$PROMETHEUS_URL/api/v1/query?query=up" > /dev/null 2>&1; then
    # We need to URL encode the query parameters for Prometheus
    METRICS_COUNT=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=count(container_memory_usage_bytes%7Bnamespace%3D%22$NAMESPACE%22%7D)" | grep -o '"value":\[[0-9.]*,"[0-9]*"\]' | grep -o '[0-9]*"' | tr -d '"')
    
    if [ -n "$METRICS_COUNT" ] && [ "$METRICS_COUNT" -gt 0 ]; then
        echo "SUCCESS: Prometheus is collecting $METRICS_COUNT metrics from OpenWhisk namespace"
    else
        echo "WARNING: No OpenWhisk metrics found in Prometheus. Dashboard may not show data."
    fi
else
    echo "WARNING: Cannot connect to Prometheus. To verify metrics collection, run:"
    echo "  kubectl port-forward svc/prometheus-server 9090:80 -n $NAMESPACE"
fi

# Final instructions
echo "======================================================================"
echo "Dashboard Fix Complete!"
echo "======================================================================"
echo ""
echo "To access the OpenWhisk dashboard:"
echo "1. Open Grafana at $GRAFANA_URL"
echo "2. Log in with username: admin, password: $GRAFANA_PASSWORD"
echo "3. Navigate to Dashboards > Browse > OpenWhisk Dashboard"
echo ""
echo "If dashboard appears empty:"
echo "  • Adjust time range in upper right corner to 'Last 12 hours'"
echo "  • Check that Prometheus is collecting metrics from OpenWhisk namespace"
echo "  • Ensure OpenWhisk pods are running and generating metrics"
echo ""
echo "Keep your port forwarding terminals open to maintain access to services:"
echo "  • OpenWhisk API: kubectl port-forward svc/owdev-nginx 31001:443 -n $NAMESPACE"
echo "  • Grafana UI: kubectl port-forward svc/grafana 3000:80 -n $NAMESPACE"
echo "  • Prometheus UI: kubectl port-forward svc/prometheus-server 9090:80 -n $NAMESPACE"
echo ""
echo "======================================================================"