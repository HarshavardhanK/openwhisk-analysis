#\!/bin/bash
# Script to import OpenWhisk dashboard into Grafana

DASHBOARD_JSON="/Users/harshavardhank/Desktop/Code/openwhisk-project/configs/monitoring/openwhisk-dashboard.json"
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="vAfZdrr3tDVT4JcoGECDRaIOOYBY8dhlFlAml7CW"

echo "Importing OpenWhisk dashboard into Grafana..."
# Import the dashboard using Grafana API
curl -X POST -H "Content-Type: application/json" -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASSWORD | base64)" "$GRAFANA_URL/api/dashboards/db" -d @- << EOFCURL
{
  "dashboard": $(cat $DASHBOARD_JSON),
  "overwrite": true
}
EOFCURL

echo -e "\nDashboard import completed\!"
echo "Please access Grafana at $GRAFANA_URL and look for 'OpenWhisk Dashboard'"
