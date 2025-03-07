#\!/bin/bash
# Main OpenWhisk management script

set -e

COMMAND=$1
shift  # Remove the command from the arguments

# Display help if no command is provided
if [ -z "$COMMAND" ]; then
    echo "OpenWhisk Management Script"
    echo "Usage: ./openwhisk.sh COMMAND [OPTIONS]"
    echo ""
    echo "Available commands:"
    echo "  deploy           - Deploy OpenWhisk"
    echo "  deploy-mac       - Deploy OpenWhisk on macOS"
    echo "  deploy-monitoring - Deploy monitoring tools"
    echo "  check-monitoring - Check status of monitoring tools"
    echo "  deploy-demo      - Deploy monitoring demo action"
    echo "  status           - Check deployment status"
    echo "  clean            - Clean up deployment"
    exit 0
fi

# Execute the appropriate script based on the command
case $COMMAND in
    deploy)
        ./scripts/deployment/deploy-openwhisk.sh "$@"
        ;;
    deploy-mac)
        ./scripts/deployment/deploy-openwhisk-mac.sh "$@"
        ;;
    deploy-monitoring)
        ./scripts/monitoring/deploy-monitoring.sh "$@"
        ;;
    check-monitoring)
        ./scripts/monitoring/check-monitoring.sh "$@"
        ;;
    deploy-demo)
        ./scripts/monitoring/deploy-demo.sh "$@"
        ;;
    status)
        ./scripts/deployment/check-ow.sh "$@"
        ;;
    clean)
        ./scripts/deployment/cleanup.sh "$@"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run './openwhisk.sh' without arguments to see available commands"
        exit 1
        ;;
esac
