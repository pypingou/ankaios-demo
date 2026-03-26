#!/bin/bash
# fleet-get-state.sh - Query vehicle state via MQTT

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Query vehicle state via MQTT

Options:
  --json              Show full JSON response instead of table
  -h, --help          Show this help message

Environment Variables:
  VIN                 Vehicle ID (default: demo_vehicle_001)
  MQTT_BROKER         MQTT broker address (default: localhost)

Examples:
  $0                  Show workload table
  $0 --json           Show full JSON response
  VIN=vehicle_002 $0  Query different vehicle
EOF
    exit 0
}

# Parse arguments
SHOW_JSON=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            SHOW_JSON=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

VIN="${VIN:-demo_vehicle_001}"
BROKER="${MQTT_BROKER:-localhost}"
FIELD_MASK='["desiredState.workloads"]'

if [ "$SHOW_JSON" = false ]; then
    echo "🔍 Vehicle: $VIN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

RESPONSE=$(podman run --rm --network host docker.io/eclipse-mosquitto:2 sh -c "
  mosquitto_sub -h $BROKER -t 'vehicle/${VIN}/state/resp' -C 1 &
  sleep 1
  mosquitto_pub -h $BROKER -t 'vehicle/${VIN}/state/req' -m '$FIELD_MASK'
  wait
")

if [ -z "$RESPONSE" ]; then
    echo "❌ No response received"
    exit 1
fi

if [ "$SHOW_JSON" = true ]; then
    echo "$RESPONSE" | jq -C .
else
    echo "📦 Workloads:"
    printf "%-20s %-10s %-15s %s\n" "NAME" "RUNTIME" "RESTART" "TAGS"
    echo "────────────────────────────────────────────────────────────────"
    echo "$RESPONSE" | jq -r '.desired_state.workloads | to_entries[] | "\(.key)|\(.value.runtime)|\(.value.restartPolicy)|\(.value.tags | to_entries | map("\(.key)=\(.value)") |
join(", "))"' | while IFS='|' read -r name runtime restart tags; do
        printf "%-20s %-10s %-15s %s\n" "$name" "$runtime" "$restart" "$tags"
    done
fi

