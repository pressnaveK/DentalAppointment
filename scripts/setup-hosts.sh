#!/bin/bash

# Script to add Minikube hosts entries for three-host architecture
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    print_warning "Minikube is not running. Please start Minikube first:"
    echo "  minikube start"
    exit 1
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
print_status "Minikube IP: $MINIKUBE_IP"

# Define the hosts entries
HOSTS_ENTRY="$MINIKUBE_IP pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com"

# Check if entries already exist
if grep -q "pressnavek-appointment-app.gromosome.com" /etc/hosts 2>/dev/null; then
    print_warning "Hosts entries already exist in /etc/hosts"
    echo "Current entries:"
    grep "pressnavek-appointment-app.gromosome.com" /etc/hosts || true
    echo ""
    read -p "Do you want to update them? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove old entries
        print_status "Removing old entries..."
        sudo sed -i '/pressnavek-appointment-app.gromosome.com/d' /etc/hosts
        sudo sed -i '/admin-pressnavek-appointment-app.gromosome.com/d' /etc/hosts  
        sudo sed -i '/api-pressnavek-appointment-app.gromosome.com/d' /etc/hosts
    else
        print_warning "Keeping existing entries. Exiting."
        exit 0
    fi
fi

# Add new hosts entry
print_status "Adding hosts entries to /etc/hosts..."
echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts > /dev/null

print_success "Hosts entries added successfully!"

echo ""
echo "=========================="
echo "   HOSTS CONFIGURATION   "
echo "=========================="
echo ""
echo "Added to /etc/hosts:"
echo "  $HOSTS_ENTRY"
echo ""
echo "You can now access:"
echo "  Client UI:  http://pressnavek-appointment-app.gromosome.com"
echo "  Admin UI:   http://admin-pressnavek-appointment-app.gromosome.com"
echo "  API:        http://api-pressnavek-appointment-app.gromosome.com"
echo ""
echo "Test connectivity:"
echo "  curl http://pressnavek-appointment-app.gromosome.com"
echo "  curl http://admin-pressnavek-appointment-app.gromosome.com"
echo "  curl http://api-pressnavek-appointment-app.gromosome.com/health"
echo "  curl http://api-pressnavek-appointment-app.gromosome.com/bot/health"
echo ""

# Verify entries
print_status "Verifying hosts entries..."
if grep -q "$MINIKUBE_IP.*pressnavek-appointment-app.gromosome.com" /etc/hosts; then
    print_success "Hosts entries verified successfully!"
else
    print_warning "Hosts entries may not have been added correctly."
fi