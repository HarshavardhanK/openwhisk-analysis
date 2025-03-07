# OpenWhisk on Kubernetes Project

This repository contains scripts and configuration files for deploying Apache OpenWhisk on Kubernetes, with support for both x86 and ARM64 architectures.

## Project Structure

```
├── actions/            # Sample OpenWhisk actions
├── configs/            # Configuration files
│   ├── monitoring/     # Monitoring configuration
│   ├── cluster.yaml    # Kubernetes cluster configuration
│   ├── mycluster.yaml  # OpenWhisk deployment configuration
├── scripts/            # Deployment and utility scripts
│   ├── deployment/     # OpenWhisk deployment scripts 
│   ├── monitoring/     # Monitoring deployment scripts
├── Makefile            # Easy access to common commands
```

## Quick Start

### Deploy OpenWhisk

To deploy OpenWhisk using the standard script:

```bash
make deploy
```

For macOS with Apple Silicon:

```bash
make deploy-mac
```

### Deploy Monitoring

To deploy Prometheus and Grafana for monitoring:

```bash
make deploy-monitoring
```

### Other Commands

```bash
# Check OpenWhisk status
make status

# Clean up OpenWhisk deployment
make clean
```

## Architecture Support

The deployment scripts automatically detect your system architecture and configure OpenWhisk appropriately:

- For x86_64/amd64: Uses standard images
- For ARM64/aarch64: Uses compatible images including Zookeeper 3.8

## Monitoring

The monitoring stack consists of:

- Prometheus for metrics collection
- Grafana for visualization and dashboards

After deployment, you can access:
- Prometheus UI: http://minikube-ip:30900
- Grafana UI: http://minikube-ip:30300 (default username: admin)

## Sample Actions

The `actions/` directory contains sample OpenWhisk actions to get you started.
