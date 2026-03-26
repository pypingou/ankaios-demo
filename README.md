# Ankaios on AutoSD QM Partition Demo

This demo shows how to deploy Eclipse Ankaios container orchestrator on Red Hat Automotive Stream Distribution (AutoSD) within the QM (Quality Managed) partition for mixed-criticality systems.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│             AutoSD Host (Root Partition)            │
│                 Critical Workloads                  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │      QM Partition (/usr/lib/qm)               │  │
│  │      Non-Critical Workloads                   │  │
│  │                                               │  │
│  │  ┌──────────────────────────────────────┐     │  │
│  │  │  Ankaios Orchestrator                │     │  │
│  │  │  ├─ ank-server (systemd service)     │     │  │
│  │  │  └─ ank-agent (systemd service)      │     │  │
│  │  └──────────────────────────────────────┘     │  │
│  │                                               │  │
│  │  ┌──────────────────────────────────────┐     │  │
│  │  │  Orchestrated Containers             │     │  │
│  │  │  ├─ nginx (web server example)       │     │  │
│  │  │  ├─ hello-world (test container)     │     │  │
│  │  │  └─ fleet-connector (MQTT bridge)    │     │  │
│  │  └──────────────────────────────────────┘     │  │
│  │                                               │  │
│  │  Podman (QM instance)                         │  │
│  │  systemd (QM instance)                        │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  Podman (Root instance)                             │
│  systemd (Root instance)                            │
└─────────────────────────────────────────────────────┘
```

## Why QM Partition for Ankaios?

1. **Isolation**: Ankaios is a QM-level (non-critical) orchestrator managing non-critical containerized workloads
2. **Freedom from Interference**: QM partition isolates Ankaios from critical applications in root partition
3. **Resource Management**: QM partition can be throttled/terminated under memory pressure to protect critical workloads
4. **Security**: Dedicated SELinux labels and cgroups for QM workloads

## Quick Start

### Generate Certificates

First, generate the mTLS certificates for secure communication:

```bash
./generate-certs.sh
```

This creates a `certs/` directory with CA, server, agent, and CLI certificates.

**Note**: Certificates are git-ignored and must be generated locally for security.

### Build Fleet Connector Container

The fleet connector enables remote MQTT-based workload management and must be built before creating the image:

```bash
cd containers/fleet-connector
./build.sh
cd ../..
```

### Configure MQTT Broker Address

Update the MQTT broker IP address in `configs/state.yaml` to match your laptop's IP:

```bash
# Edit configs/state.yaml and change MQTT_BROKER_ADDR
# From: MQTT_BROKER_ADDR=192.168.1.22
# To:   MQTT_BROKER_ADDR=<your-laptop-ip>
```

**Tip**: Find your laptop's IP with `ip addr show` or `hostname -I`

### Build the Image

```bash
./build.sh
```

### Boot the Image

```bash
air --nographics ankaios-demo.$(arch).img
```

Login: `root` / `password`

### Verify Deployment

```bash
# Check QM partition status
systemctl status qm

# Check Ankaios services in QM partition
podman exec qm systemctl status ank-server
podman exec qm systemctl status ank-agent

# View orchestrated workloads
podman exec qm ank get workloads

# See running containers
podman exec qm podman ps
```

## Working with Ankaios

### Access QM Partition

```bash
# From root partition, execute commands in QM
podman exec qm ank get state
podman exec qm ank get workloads
podman exec qm podman ps

# Or get an interactive shell
podman exec -it qm /bin/bash
```

### Deploy a New Workload

```bash
# Create a manifest on the host
cat > /tmp/my-app.yaml <<EOF
apiVersion: v1
workloads:
  my-app:
    runtime: podman
    agent: qm_agent
    restartPolicy: ALWAYS
    tags:
      app: my-application
    runtimeConfig: |
      image: docker.io/httpd:latest
      commandOptions: ["-p", "3000:80"]
EOF

# Copy it to QM partition
podman cp /tmp/my-app.yaml qm:/tmp/

# Apply it
podman exec qm ank apply /tmp/my-app.yaml

# Verify
podman exec qm ank get workloads
podman exec qm podman ps
```

### View Logs

```bash
# QM partition logs
journalctl -u qm -f

# Ankaios server logs
podman exec qm journalctl -u ank-server -f

# Ankaios agent logs
podman exec qm journalctl -u ank-agent -f

# Container logs
podman exec qm podman logs <container-name>
```

## File Structure

```
ankaios-demo/
├── ankaios-demo.aib.yml       # AutoSD Image Builder manifest
├── build.sh                    # Build script
├── generate-certs.sh           # Certificate generation script
├── test-ankaios.sh             # Automated test script
├── configs/
│   ├── ank-server.conf        # Ankaios server configuration
│   ├── ank-agent.conf         # Ankaios agent configuration
│   ├── ank.conf               # Ankaios CLI configuration
│   └── state.yaml             # Initial workload manifest
├── containers/
│   └── fleet-connector/       # MQTT-based fleet management
│       ├── fleet-connector.py # Main connector service
│       ├── fleet-*.sh         # Management scripts
│       └── README.md          # Fleet connector documentation
├── certs/ (generated)          # mTLS certificates (git-ignored)
│   ├── ca.pem                 # Certificate Authority
│   ├── server.pem/key.pem     # Server certificates
│   ├── agent.pem/key.pem      # Agent certificates
│   └── cli.pem/key.pem        # CLI certificates
└── README.md                   # This file
```

## Configuration Details

### QM Partition Paths

- **QM Root**: `/usr/lib/qm/` (from host perspective)
- **Ankaios binaries**: `/usr/lib/qm/usr/bin/ank*`
- **Configuration**: `/usr/lib/qm/etc/ankaios/`
- **Certificates**: `/usr/lib/qm/etc/ankaios/certs/`
- **Container storage**: `/usr/lib/qm/var/lib/containers/`

### Security

The demo uses **mTLS (mutual TLS)** for all Ankaios communication:
- Server authenticates with `server.pem`
- Agent authenticates with `agent.pem`
- CLI authenticates with `cli.pem`
- All signed by the same CA (`ca.pem`)

This ensures encrypted and authenticated communication between all Ankaios components.

**Important**: Certificates are NOT included in the repository for security reasons. Run `./generate-certs.sh` before building the image.

### Resource Limits

The QM partition is configured with:
- **Memory max**: 50% of system memory
- **Memory high**: 45% threshold
- Controlled by cgroups for isolation

### Sample Workloads

Three demo containers are pre-configured in `configs/state.yaml`:

1. **nginx-demo**: Web server on port 8080
2. **hello-world**: Simple test container
3. **fleet-connector**: MQTT bridge for remote workload management (requires external MQTT broker)

## Troubleshooting

### QM Partition Not Starting

```bash
systemctl status qm
journalctl -u qm
systemctl restart qm
```

### Ankaios Services Not Running

```bash
podman exec qm systemctl status ank-server
podman exec qm journalctl -u ank-server -n 50
podman exec qm systemctl restart ank-server
```

### Containers Not Starting

```bash
podman exec qm ank get workloads
podman exec qm podman ps -a
podman exec qm podman logs <container-name>
```

## Resources

- [Eclipse Ankaios Documentation](https://eclipse-ankaios.github.io/ankaios)
- [AutoSD Mixed Criticality Concepts](https://sigs.centos.org/automotive/building/concepts/mixed-criticality/)
- [AutoSD Documentation](https://sigs.centos.org/automotive/)
