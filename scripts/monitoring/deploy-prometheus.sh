#!/bin/bash
# Modular Prometheus deployment script for OpenWhisk monitoring

set -e

# Get the Minikube IP
MINIKUBE_IP=${1:-$(minikube ip)}
NAMESPACE=${2:-openwhisk}

echo "Deploying Prometheus to monitor OpenWhisk in namespace: $NAMESPACE"
echo "Using Minikube IP: $MINIKUBE_IP"

# Add Prometheus Helm repo if needed
if ! helm repo list | grep -q "prometheus-community"; then
    echo "Adding Prometheus Helm repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
fi

# Create values file for Prometheus
cat > prometheus-values.yaml << EOF
alertmanager:
  persistentVolume:
    enabled: true
    size: 1Gi
server:
  persistentVolume:
    enabled: true
    size: 4Gi
  service:
    type: NodePort
    nodePort: 30900
  # OpenWhisk-specific scrape configurations
  extraScrapeConfigs: |
    - job_name: 'openwhisk'
      kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
              - $NAMESPACE
      relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
          action: replace
          target_label: __scheme__
          regex: (https?)
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
          action: replace
          target_label: __address__
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: \$1:\$2
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_service_name]
          action: replace
          target_label: kubernetes_name
EOF

# Check if Prometheus is already installed
if helm list -n $NAMESPACE | grep -q "prometheus"; then
    echo "Prometheus is already installed. Upgrading instead..."
    helm upgrade prometheus prometheus-community/prometheus \
      --namespace $NAMESPACE \
      --values prometheus-values.yaml
else
    echo "Installing Prometheus..."
    helm install prometheus prometheus-community/prometheus \
      --namespace $NAMESPACE \
      --values prometheus-values.yaml
fi

# Wait for deployment to be ready
echo "Waiting for Prometheus server to be ready..."
kubectl rollout status deployment/prometheus-server -n $NAMESPACE

echo "Prometheus deployed successfully!"
echo "Prometheus UI: http://$MINIKUBE_IP:30900"