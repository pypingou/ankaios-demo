#!/bin/bash
# Generate mTLS certificates for Ankaios deployment
# This script uses the certificate generation tool from the Ankaios project

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CERTS_DIR="$SCRIPT_DIR/certs"
ANKAIOS_CERT_SCRIPT="$SCRIPT_DIR/../ankaios/tools/certs/create_certs.sh"

echo "Generating Ankaios mTLS certificates..."
echo ""

# Check if the Ankaios cert script exists
if [ ! -f "$ANKAIOS_CERT_SCRIPT" ]; then
    echo "Error: Ankaios certificate generation script not found at:"
    echo "  $ANKAIOS_CERT_SCRIPT"
    echo ""
    echo "Please ensure the Ankaios repository is cloned alongside this project:"
    echo "  Expected location: ../ankaios"
    echo ""
    echo "Or manually generate certificates using openssl:"
    echo "  See https://eclipse-ankaios.github.io/ankaios for details"
    exit 1
fi

# Create certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"

# Generate certificates
bash "$ANKAIOS_CERT_SCRIPT" "$CERTS_DIR"

echo ""
echo "✓ Certificates generated in: $CERTS_DIR"
echo ""
echo "Generated files:"
ls -1 "$CERTS_DIR"
echo ""
echo "Next step: Build the AutoSD image"
echo "  ./build.sh"
