#!/bin/bash

# Script to create SSL secret from Cloudflare certificate files
# Usage: ./create-ssl-secret.sh /path/to/certificate.pem /path/to/private.key

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <certificate-file> <private-key-file>"
    echo "Example: $0 certificate.pem private.key"
    exit 1
fi

CERT_FILE="$1"
KEY_FILE="$2"
SECRET_NAME="cloudflare-ssl-cert"
NAMESPACE="chat-appointment"

# Check if files exist
if [ ! -f "$CERT_FILE" ]; then
    echo "Certificate file not found: $CERT_FILE"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Private key file not found: $KEY_FILE"
    exit 1
fi

echo "Creating SSL secret from Cloudflare certificate..."

# Delete existing secret if it exists
kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found=true

# Create the TLS secret
kubectl create secret tls $SECRET_NAME \
    --cert="$CERT_FILE" \
    --key="$KEY_FILE" \
    -n $NAMESPACE

echo "SSL secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'"

# Verify the secret
echo "Secret details:"
kubectl describe secret $SECRET_NAME -n $NAMESPACE

# Check certificate expiration
echo "Certificate information:"
openssl x509 -in "$CERT_FILE" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"