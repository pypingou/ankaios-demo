# Ankaios Fleet Connector

Bridge service enabling remote MQTT-based management of Ankaios workloads across vehicles/devices.

```
MQTT Broker (cloud) → Fleet Connector (vehicle) → Ankaios → Workloads
```

## Quick Start (AIB Demo)

**✅ Pre-configured in this demo's AutoSD image:**
- Fleet connector auto-deployed at boot
- Control interface permissions configured
- Ankaios server/agent running

**🔧 Steps:**

1. **Start MQTT broker** (laptop):
   ```bash
   podman run --rm -it --net=host eclipse-mosquitto:2.0.20
   ```

2. **Boot AutoSD image** (fleet connector starts automatically)

3. **Manage remotely** (laptop):
   ```bash
   ./fleet-get-state.sh              # Check workloads
   ./fleet-apply.sh workload.yaml    # Deploy
   ./fleet-delete.sh workload_name   # Remove
   ```

## Management Scripts

### `fleet-get-state.sh` - Query Workloads

```bash
./fleet-get-state.sh              # Table view
./fleet-get-state.sh --json       # Full JSON
VIN=vehicle_002 ./fleet-get-state.sh
```

### `fleet-apply.sh` - Deploy Workloads

```bash
./fleet-apply.sh manifest.yaml
VIN=vehicle_002 ./fleet-apply.sh manifest.yaml
```

Example manifest:
```yaml
apiVersion: v1
workloads:
  my_app:
    agent: qm_agent
    runtime: podman
    restartPolicy: ALWAYS
    runtimeConfig: |
      image: localhost/my-app:latest
```

### `fleet-delete.sh` - Remove Workloads

```bash
./fleet-delete.sh workload_name   # Auto-generates manifest
./fleet-delete.sh manifest.yaml   # From file
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VIN` | `demo_vehicle_001` | Vehicle ID |
| `MQTT_BROKER` | `localhost` | Broker address |
| `AGENT` | `qm_agent` | Agent name (for auto-manifests) |
| `RUNTIME` | `podman` | Runtime (for auto-manifests) |

## MQTT Topics

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `vehicle/<VIN>/manifest/apply/req` | → Vehicle | Deploy workload |
| `vehicle/<VIN>/manifest/apply/resp` | ← Vehicle | Deploy result |
| `vehicle/<VIN>/manifest/delete/req` | → Vehicle | Delete workload |
| `vehicle/<VIN>/manifest/delete/resp` | ← Vehicle | Delete result |
| `vehicle/<VIN>/state/req` | → Vehicle | Query state |
| `vehicle/<VIN>/state/resp` | ← Vehicle | State response |

## Troubleshooting

**No response from fleet connector:**
```bash
ank get workloads | grep fleet_connector  # Check status
podman logs <fleet_connector_container>   # Check logs
```

**Control interface error:**
- Ensure `controlInterfaceAccess` is in manifest

## References

- [Ankaios Control Interface](https://eclipse-ankaios.github.io/ankaios/latest/reference/control-interface/)
- [Ankaios SDK Python](https://github.com/eclipse-ankaios/ank-sdk-python)
- [Eclipse Mosquitto](https://mosquitto.org/)
