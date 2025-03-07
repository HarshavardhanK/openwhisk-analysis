#!/bin/bash
# Modular Grafana deployment script for OpenWhisk monitoring

set -e

# Get the Minikube IP
MINIKUBE_IP=${1:-$(minikube ip)}
NAMESPACE=${2:-openwhisk}
PROMETHEUS_SVC=${3:-prometheus-server}

echo "Deploying Grafana to visualize OpenWhisk metrics in namespace: $NAMESPACE"
echo "Using Minikube IP: $MINIKUBE_IP"
echo "Using Prometheus service: $PROMETHEUS_SVC.$NAMESPACE.svc.cluster.local"

# Add Grafana Helm repo if needed
if ! helm repo list | grep -q "grafana"; then
    echo "Adding Grafana Helm repository..."
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
fi

# Set a specific chart version to avoid compatibility issues
GRAFANA_CHART_VERSION="6.58.8"
echo "Using Grafana Helm chart version: $GRAFANA_CHART_VERSION"

# Create values file for Grafana
cat > grafana-values.yaml << EOF
persistence:
  enabled: true
  size: 2Gi
service:
  type: NodePort
  nodePort: 30300
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://$PROMETHEUS_SVC.$NAMESPACE.svc.cluster.local
      access: proxy
      isDefault: true
EOF

# Check if Grafana is already installed
if helm list -n $NAMESPACE | grep -q "grafana"; then
    echo "Grafana is already installed. Upgrading instead..."
    helm upgrade grafana grafana/grafana \
      --namespace $NAMESPACE \
      --values grafana-values.yaml \
      --version $GRAFANA_CHART_VERSION
else
    echo "Installing Grafana..."
    helm install grafana grafana/grafana \
      --namespace $NAMESPACE \
      --values grafana-values.yaml \
      --version $GRAFANA_CHART_VERSION
fi

# Wait for deployment to be ready
echo "Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n $NAMESPACE

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

# Create OpenWhisk dashboard JSON file
cat > openwhisk-dashboard.json << 'EOF'
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(container_memory_usage_bytes{namespace=\"openwhisk\", container!=\"POD\"}) by (pod)",
          "interval": "",
          "legendFormat": "{{pod}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "OpenWhisk Memory Usage by Pod",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "bytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 4,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"openwhisk\", container!=\"POD\"}[5m])) by (pod)",
          "interval": "",
          "legendFormat": "{{pod}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "OpenWhisk CPU Usage by Pod",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null,
            "filterable": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 6,
      "options": {
        "showHeader": true
      },
      "targets": [
        {
          "expr": "kube_pod_info{namespace=\"openwhisk\"}",
          "format": "table",
          "instant": true,
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "OpenWhisk Pods Status",
      "type": "table"
    }
  ],
  "refresh": "10s",
  "schemaVersion": 26,
  "style": "dark",
  "tags": [
    "openwhisk",
    "kubernetes"
  ],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "OpenWhisk Dashboard",
  "uid": "openwhisk-dashboard",
  "version": 1
}
EOF

# Create the script to import the dashboard via API
cat > import-dashboard.sh << EOF
#!/bin/bash
# Script to import OpenWhisk dashboard into Grafana

MINIKUBE_IP=\${1:-\$(minikube ip)}
NAMESPACE=\${2:-openwhisk}
GRAFANA_PASSWORD=\${3:-\$(kubectl get secret -n \$NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)}

GRAFANA_URL="http://\$MINIKUBE_IP:30300"

echo "Importing OpenWhisk dashboard into Grafana..."
# Import the dashboard using Grafana API
curl -X POST -H "Content-Type: application/json" -H "Authorization: Basic \$(echo -n admin:\$GRAFANA_PASSWORD | base64)" "\$GRAFANA_URL/api/dashboards/db" -d @- << EOFCURL
{
  "dashboard": \$(cat openwhisk-dashboard.json),
  "overwrite": true
}
EOFCURL

echo -e "\nDashboard import completed!"
EOF

# Make the import script executable
chmod +x import-dashboard.sh

echo "Grafana deployed successfully!"
echo "Grafana URL: http://$MINIKUBE_IP:30300"
echo "Grafana admin username: admin"
echo "Grafana admin password: $GRAFANA_PASSWORD"
echo ""
echo "To import the OpenWhisk dashboard, run:"
echo "./import-dashboard.sh"