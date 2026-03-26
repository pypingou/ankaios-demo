#!/bin/bash
# fleet-apply.sh - Apply manifest to vehicle via MQTT

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] <manifest.yaml>

Apply a workload manifest to a vehicle via MQTT

Options:
  -h, --help          Show this help message

Environment Variables:
  VIN                 Vehicle ID (default: demo_vehicle_001)
  MQTT_BROKER         MQTT broker address (default: localhost)

Examples:
  $0 my-workload.yaml
  VIN=vehicle_002 $0 my-workload.yaml
  MQTT_BROKER=192.168.1.100 $0 my-workload.yaml
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
            MANIFEST_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$MANIFEST_FILE" ]; then
    echo "Error: No manifest file specified"
    echo "Use -h or --help for usage information"
    exit 1
fi

VIN="${VIN:-demo_vehicle_001}"
BROKER="${MQTT_BROKER:-localhost}"

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "Error: File '$MANIFEST_FILE' not found"
    exit 1
fi

echo "📤 Applying manifest to vehicle: $VIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Manifest:"
cat "$MANIFEST_FILE"
echo ""

MANIFEST=$(cat "$MANIFEST_FILE")

# Subscribe for response and send request
RESPONSE=$(podman run --rm --network host docker.io/eclipse-mosquitto:2 sh -c "
  mosquitto_sub -h $BROKER -t 'vehicle/${VIN}/manifest/apply/resp' -C 1 &
  sleep 1
  mosquitto_pub -h $BROKER -t 'vehicle/${VIN}/manifest/apply/req' -m '$MANIFEST'
  wait
")

echo "📨 Response:"
if [ -n "$RESPONSE" ]; then
    echo "$RESPONSE" | jq -C .
else
    echo "❌ No response received from fleet connector"
fi
