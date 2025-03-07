#\!/bin/bash
# Script to check if Prometheus is capturing OpenWhisk metrics

echo "Checking if Prometheus is capturing OpenWhisk metrics..."
echo "Setting up port forwarding to Prometheus..."
kubectl port-forward svc/prometheus-server 9090:80 -n openwhisk &
PROM_PID=$\!
sleep 3

echo "Checking if prometheus is collecting any metrics for OpenWhisk containers..."
curl -s "http://localhost:9090/api/v1/query?query=count(container_memory_usage_bytes{namespace=%22openwhisk%22})" | jq .

echo "Checking which pod metrics are being collected..."
curl -s "http://localhost:9090/api/v1/query?query=container_memory_usage_bytes{namespace=%22openwhisk%22}" | jq '.data.result[] | .metric.pod' | sort | uniq

echo "Checking Prometheus targets status..."
curl -s "http://localhost:9090/api/v1/query?query=up" | jq .

echo "Killing port-forward process..."
kill $PROM_PID

echo "Done checking Prometheus metrics"
