#!/bin/bash
# fleet-delete.sh - Delete workload via MQTT

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] <manifest.yaml|workload_name>

Delete a workload from a vehicle via MQTT

Options:
  -h, --help          Show this help message

Arguments:
  manifest.yaml       YAML file with workload(s) to delete
  workload_name       Name of workload to delete (will create manifest)

Environment Variables:
  VIN                 Vehicle ID (default: demo_vehicle_001)
  MQTT_BROKER         MQTT broker address (default: localhost)
  AGENT               Agent name for auto-generated manifest (default: qm_agent)
  RUNTIME             Runtime for auto-generated manifest (default: podman)

Examples:
  $0 mqtt_test                        Delete by name
  $0 delete-manifest.yaml             Delete using manifest file
  VIN=vehicle_002 $0 mqtt_test        Delete from specific vehicle
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

if [ -z "$TARGET" ]; then
    echo "Error: No manifest file or workload name specified"
    echo "Use -h or --help for usage information"
    exit 1
fi

VIN="${VIN:-demo_vehicle_001}"
BROKER="${MQTT_BROKER:-localhost}"
AGENT="${AGENT:-qm_agent}"
RUNTIME="${RUNTIME:-podman}"

# Check if it's a file or workload name
if [ -f "$TARGET" ]; then
    MANIFEST=$(cat "$TARGET")
else
    # Create minimal delete manifest
    MANIFEST="apiVersion: v1
workloads:
  $TARGET:
    agent: $AGENT
    runtime: $RUNTIME
    runtimeConfig: |
      image: dummy"
fi

echo "🗑️   Deleting from vehicle: $VIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Manifest:"
echo "$MANIFEST"
echo ""

# Subscribe for response
RESPONSE=$(podman run --rm --network host docker.io/eclipse-mosquitto:2 sh -c "
  mosquitto_sub -h $BROKER -t 'vehicle/${VIN}/manifest/delete/resp' -C 1 &
  sleep 1
  mosquitto_pub -h $BROKER -t 'vehicle/${VIN}/manifest/delete/req' -m '$MANIFEST'
  wait
")

echo "📨 Response:"
if [ -n "$RESPONSE" ]; then
    echo "$RESPONSE" | jq -C .
else
    echo "❌ No response received from fleet connector"
fi
