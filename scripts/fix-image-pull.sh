#!/bin/bash

# Quick fix script for ErrImageNeverPull issues
# This script builds all Docker images directly in Minikube's Docker daemon

set -e

# Colors for output
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "api" ] || [ ! -d "ui" ] || [ ! -d "k8s" ]; then
    print_error "Please run this script from the ChatAppointment project root directory"
    exit 1
fi

print_status "Fixing ErrImageNeverPull issues by building images in Minikube..."

# Configure Docker to use Minikube's Docker daemon
print_status "Configuring Docker to use Minikube's daemon..."
eval $(minikube docker-env)

if [ $? -ne 0 ]; then
    print_error "Failed to configure Docker for Minikube. Is Minikube running?"
    print_status "Try: minikube start"
    exit 1
fi

# Build all images
print_status "Building bot-service image..."
docker build -t chat-appointment/bot-service:latest ./api/bot_service/
if [ $? -eq 0 ]; then
    print_success "Bot service image built successfully"
else
    print_error "Failed to build bot-service image"
    exit 1
fi

print_status "Building user-service image..."
docker build -t chat-appointment/user-service:latest ./api/user_service/
if [ $? -eq 0 ]; then
    print_success "User service image built successfully"
else
    print_error "Failed to build user-service image"
    exit 1
fi

print_status "Building admin-ui image..."
docker build -t chat-appointment/admin-ui:latest ./ui/admin_ui/
if [ $? -eq 0 ]; then
    print_success "Admin UI image built successfully"
else
    print_error "Failed to build admin-ui image"
    exit 1
fi

print_status "Building client-ui image..."
docker build -t chat-appointment/client-ui:latest ./ui/client_ui/
if [ $? -eq 0 ]; then
    print_success "Client UI image built successfully"
else
    print_error "Failed to build client-ui image"
    exit 1
fi

# Verify all images are present
print_status "Verifying built images..."
docker images | grep chat-appointment

print_success "All images built successfully!"

# Restart deployments to pick up the new images
print_status "Restarting Kubernetes deployments..."
kubectl rollout restart deployment/bot-service -n chat-appointment
kubectl rollout restart deployment/user-service -n chat-appointment
kubectl rollout restart deployment/admin-ui -n chat-appointment
kubectl rollout restart deployment/client-ui -n chat-appointment

print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment --all -n chat-appointment --timeout=300s

if [ $? -eq 0 ]; then
    print_success "All deployments are now ready!"
    
    print_status "Checking pod status..."
    kubectl get pods -n chat-appointment
    
    print_status "Testing health endpoints..."
    MINIKUBE_IP=$(minikube ip)
    echo ""
    echo "You can now test your applications:"
    echo "  User Service Health: curl http://$MINIKUBE_IP/health"
    echo "  Bot Service Health:  curl http://$MINIKUBE_IP/bot/health"
    echo ""
    echo "Or use the domain names if DNS is configured:"
    echo "  curl http://api-pressnavek-appointment-app.gromosome.com/health"
    echo "  curl http://api-pressnavek-appointment-app.gromosome.com/bot/health"
    echo "  curl http://admin-pressnavek-appointment-app.gromosome.com/"
    echo "  curl http://pressnavek-appointment-app.gromosome.com/"
    
else
    print_error "Some deployments failed to become ready. Check the logs:"
    echo "  kubectl get pods -n chat-appointment"
    echo "  kubectl logs deployment/bot-service -n chat-appointment"
    echo "  kubectl logs deployment/user-service -n chat-appointment"
    exit 1
fi

print_success "Image build and deployment fix completed successfully!"