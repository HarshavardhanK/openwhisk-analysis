helm repo add openwhisk https://openwhisk.apache.org/charts
helm repo update

#From the directory of OpenWhish Deploy Kube
helm install owdev openwhisk/openwhisk -n openwhisk --create-namespace -f mycluster.yaml


#Connect the OW CLI
wsk property set --apihost localhost:31001


docker pull --platform=linux/amd64 zookeeper:3.4

# Step 2: Load the image into Minikube's local image cache
echo "Loading zookeeper:3.4 into Minikube..."
minikube image load zookeeper:3.4

# Step 3: Delete the current Zookeeper pod so that Kubernetes redeploys it using the local image
# Adjust the label or pod name as needed; here we assume the pod name starts with 'owdev-zookeeper'
echo "Deleting the existing Zookeeper pod..."
kubectl delete pod -n openwhisk -l name=owdev-zookeeper

#Port Forward

kubectl port-forward svc/owdev-nginx 31001:443 -n openwhisk