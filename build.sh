#!/bin/bash
# Build script for Ankaios on AutoSD demo image

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

arch=$(arch)

echo "============================================"
echo "Building Ankaios on AutoSD Demo Image"
echo "============================================"
echo ""
echo "Architecture: $arch"
echo "Build directory: _build"
echo ""

# Check prerequisites
if ! command -v aib &> /dev/null; then
    echo "Error: 'aib' (Automotive Image Builder) not found"
    echo "Please install it first:"
    echo "  https://gitlab.com/CentOS/automotive/src/automotive-image-builder"
    exit 1
fi

# Verify config files exist
if [ ! -f "configs/ank-server.conf" ]; then
    echo "Error: configs/ank-server.conf not found"
    exit 1
fi

if [ ! -f "configs/ank-agent.conf" ]; then
    echo "Error: configs/ank-agent.conf not found"
    exit 1
fi

if [ ! -f "configs/state.yaml" ]; then
    echo "Error: configs/state.yaml not found"
    exit 1
fi

# Verify certificates exist
if [ ! -d "certs" ] || [ ! -f "certs/ca.pem" ]; then
    echo "Error: Certificates not found in certs/ directory"
    echo "Please run ./generate-certs.sh first to create mTLS certificates"
    exit 1
fi

echo "Starting build..."
echo ""

# Build the image
aib --verbose \
    build \
    --distro autosd10 \
    --target qemu \
    --build-dir=_build \
    ankaios-demo.aib.yml \
    ankaios-demo \
    "ankaios-demo.${arch}.img"

echo ""
echo "============================================"
echo "Build Complete!"
echo "============================================"
echo ""
echo "Image: ankaios-demo.${arch}.img"
echo ""
echo "To boot the image:"
echo "  air --nographics ankaios-demo.${arch}.img"
echo ""
echo "Login credentials:"
echo "  Username: root"
echo "  Password: password"
echo ""
echo "Quick verification:"
echo "  systemctl status qm"
echo "  podman exec qm ank get workloads"
echo ""
