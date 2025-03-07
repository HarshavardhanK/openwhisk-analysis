# OpenWhisk Project Makefile

.PHONY: deploy deploy-mac deploy-monitoring clean status help

# Default target
help:
	@echo "OpenWhisk Project Makefile"
	@echo "------------------------"
	@echo "Available targets:"
	@echo "  deploy            - Deploy OpenWhisk on Kubernetes"
	@echo "  deploy-mac        - Deploy OpenWhisk on macOS with Minikube"
	@echo "  deploy-monitoring - Deploy Prometheus and Grafana monitoring"
	@echo "  clean             - Clean up OpenWhisk deployment"
	@echo "  status            - Check OpenWhisk deployment status"

# Deploy OpenWhisk
deploy:
	@echo "Deploying OpenWhisk..."
	@scripts/deployment/deploy-openwhisk.sh

# Deploy OpenWhisk on macOS
deploy-mac:
	@echo "Deploying OpenWhisk on macOS..."
	@scripts/deployment/deploy-mac.sh

# Deploy monitoring stack
deploy-monitoring:
	@echo "Deploying monitoring stack (Prometheus + Grafana)..."
	@scripts/monitoring/deploy-monitoring.sh

# Clean up deployment
clean:
	@echo "Cleaning up OpenWhisk deployment..."
	@scripts/deployment/cleanup.sh

# Check status
status:
	@echo "Checking OpenWhisk status..."
	@scripts/deployment/check-ow.sh

# Check monitoring status
check-monitoring:
	@echo "Checking monitoring status..."
	@scripts/monitoring/check-monitoring.sh

# Deploy monitoring demo action
deploy-demo:
	@echo "Deploying monitoring demo action..."
	@scripts/monitoring/deploy-demo.sh
