#!/bin/bash
# Test script to verify Ankaios deployment in AutoSD QM partition

set -e

echo "==================================="
echo "Ankaios on AutoSD QM Partition Test"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Test 1: Check QM partition is running
echo "Test 1: QM Partition Status"
if systemctl is-active --quiet qm; then
    success "QM partition is running"
    systemctl status qm --no-pager | head -n 5
else
    error "QM partition is not running"
    exit 1
fi
echo ""

# Test 2: Check Ankaios server in QM partition
echo "Test 2: Ankaios Server Status"
if podman exec qm systemctl is-active --quiet ank-server; then
    success "Ankaios server is running in QM partition"
    podman exec qm systemctl status ank-server --no-pager | head -n 10
else
    error "Ankaios server is not running"
    podman exec qm systemctl status ank-server --no-pager
fi
echo ""

# Test 3: Check Ankaios agent in QM partition
echo "Test 3: Ankaios Agent Status"
if podman exec qm systemctl is-active --quiet ank-agent; then
    success "Ankaios agent is running in QM partition"
    podman exec qm systemctl status ank-agent --no-pager | head -n 10
else
    error "Ankaios agent is not running"
    podman exec qm systemctl status ank-agent --no-pager
fi
echo ""

# Test 4: Check Ankaios workloads
echo "Test 4: Ankaios Workloads"
info "Listing workloads managed by Ankaios..."
podman exec qm ank get workloads || {
    error "Failed to get workloads"
    exit 1
}
echo ""

# Test 5: Check Podman containers in QM partition
echo "Test 5: Podman Containers in QM Partition"
info "Listing running containers..."
podman exec qm podman ps || {
    error "Failed to list containers"
    exit 1
}
echo ""

# Test 6: Verify nginx workload
echo "Test 6: Nginx Workload Accessibility"
if podman exec qm podman ps | grep -q nginx; then
    success "Nginx container is running"
    info "Testing nginx accessibility..."
    if podman exec qm curl -s http://localhost:8080 | grep -q "Welcome to nginx"; then
        success "Nginx is serving HTTP traffic"
    else
        error "Nginx is not responding correctly"
    fi
else
    error "Nginx container is not running"
fi
echo ""

# Summary
echo "==================================="
echo "Test Summary"
echo "==================================="
success "All tests completed!"
echo ""
echo "You can interact with Ankaios from the root partition:"
echo "  podman exec qm ank get state"
echo "  podman exec qm ank get workloads"
echo "  podman exec qm podman ps"
