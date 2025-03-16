#!/bin/bash

PUBLIC_IP="130.127.xxx.xxx"  #Replace with master node's public IP
PRIVATE_IP="10.10.1.xxx"     #Replace with  master node's private IP
NODE_ROLE=$1                 #master or worker
K3S_TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
MASTER_PRIVATE_IP="<master-private-ip>"

# ------------------------
# UPDATE SYSTEM
# ------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl

# ------------------------
# INSTALL k3s
# ------------------------
if [ "$NODE_ROLE" == "master" ]; then
  echo "Installing k3s on master..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$PRIVATE_IP" sh -
else
  echo "Installing k3s on worker..."
  read -p "Enter K3S_TOKEN: " K3S_TOKEN
  curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_PRIVATE_IP:6443" K3S_TOKEN="$K3S_TOKEN" sh -
  exit 0
fi

#Export KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# INSTALL HELM
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


# INSTALL OPENWHISK
echo "Installing OpenWhisk..."

# Create values file
cat <<EOF > my-values.yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: "$PUBLIC_IP"
    apiHostPort: 31001
  configuration:
    whisk:
      sslCert: ""
      sslKey: ""
EOF

# Add Helm repo and install OpenWhisk
helm repo add openwhisk https://openwhisk.apache.org/charts
helm repo update
kubectl create namespace openwhisk
helm install owdev openwhisk/openwhisk --namespace openwhisk -f my-values.yaml

echo "Waiting for OpenWhisk pods to be ready..."
kubectl rollout status deployment/owdev-controller -n openwhisk
kubectl rollout status deployment/owdev-apigateway -n openwhisk

# ------------------------
# LABEL INVOKER NODE (RUN THIS ONLY ONCE)
# ------------------------
kubectl label node $(hostname) openwhisk-role=invoker

# ------------------------
# INSTALL wsk CLI
# ------------------------
echo "Installing wsk CLI..."
curl -LO https://github.com/apache/openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
tar -xvzf OpenWhisk_CLI-latest-linux-amd64.tgz
sudo mv wsk /usr/local/bin/

# ------------------------
# CONFIGURE wsk CLI
# ------------------------
AUTH_KEY=$(kubectl get secret owdev-whisk.auth -n openwhisk -o jsonpath="{.data.system}" | base64 --decode)

wsk property set --apihost $PUBLIC_IP:31001
wsk property set --auth $AUTH_KEY
wsk property set --cert-ignore true

echo "Setup complete! Verify with:"
echo "wsk list"
