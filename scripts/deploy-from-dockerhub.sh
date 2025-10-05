#!/bin/bash

# Manual deployment script for VPS - pulls from Docker Hub and deploys to Kubernetes
# Usage: ./scripts/deploy-from-dockerhub.sh [DOCKER_HUB_USERNAME]

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

# Configuration
DOCKER_HUB_USERNAME="${1:-pressnavek}"
NAMESPACE="chat-appointment"

print_status "Starting Docker Hub deployment for user: $DOCKER_HUB_USERNAME"

# Check required tools
for tool in kubectl minikube docker; do
    if ! command -v $tool &> /dev/null; then
        print_error "$tool is not installed or not in PATH"
        exit 1
    fi
done

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    print_status "Starting Minikube..."
    minikube start --cpus=4 --memory=4096 --disk-size=20g
else
    print_success "Minikube is already running"
fi

# Check if we're in the right directory (should have k8s folder)
if [ ! -d "k8s" ]; then
    print_error "k8s directory not found. Please run this script from the deployment directory."
    print_status "Expected directory structure:"
    print_status "  k8s/"
    print_status "  scripts/"
    exit 1
fi

# Login to Docker Hub (interactive)
print_status "Logging into Docker Hub..."
print_warning "You will be prompted for your Docker Hub password"
docker login -u "$DOCKER_HUB_USERNAME"

if [ $? -ne 0 ]; then
    print_error "Failed to login to Docker Hub"
    exit 1
fi

# Pull images from Docker Hub
print_status "Pulling Docker images from Docker Hub..."

images=(
    "chat-appointment-bot-service"
    "chat-appointment-user-service"
    "chat-appointment-admin-ui"
    "chat-appointment-client-ui"
)

for image in "${images[@]}"; do
    print_status "Pulling $DOCKER_HUB_USERNAME/$image:latest..."
    docker pull "$DOCKER_HUB_USERNAME/$image:latest"
    
    if [ $? -eq 0 ]; then
        # Tag for Kubernetes (local name)
        local_name=$(echo $image | sed 's/chat-appointment-/chat-appointment\//')
        docker tag "$DOCKER_HUB_USERNAME/$image:latest" "$local_name:latest"
        print_success "Successfully pulled and tagged $image"
    else
        print_error "Failed to pull $image"
        print_warning "Make sure the image exists: https://hub.docker.com/r/$DOCKER_HUB_USERNAME/$image"
        exit 1
    fi
done

# Verify images are available
print_status "Verifying Docker images..."
docker images | grep chat-appointment

# Create namespace if it doesn't exist
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    print_status "Creating namespace $NAMESPACE..."
    kubectl create namespace $NAMESPACE
fi

# Deploy to Kubernetes
print_status "Deploying to Kubernetes..."

# Apply manifests in order
kubectl apply -f k8s/00-namespace-config.yaml
kubectl apply -f k8s/01-storage.yaml  
kubectl apply -f k8s/02-database.yaml

# Wait for database services
print_status "Waiting for database services..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s || print_warning "Postgres not ready yet"
kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s || print_warning "Redis not ready yet"

# Deploy application services
kubectl apply -f k8s/03-bot-service.yaml
kubectl apply -f k8s/04-user-service.yaml
kubectl apply -f k8s/05-admin-ui.yaml
kubectl apply -f k8s/06-client-ui.yaml

# Deploy ingress
kubectl apply -f k8s/07-ingress.yaml

# Check SSL certificate
if kubectl get secret cloudflare-ssl-cert -n $NAMESPACE > /dev/null 2>&1; then  
    print_success "SSL certificate found - HTTPS enabled"
else
    print_warning "SSL certificate not found - HTTP only"
    if [ -f "k8s/08-ssl-secret.yaml" ]; then
        print_status "To enable HTTPS: kubectl apply -f k8s/08-ssl-secret.yaml"
    fi
fi

# Wait for application deployments
print_status "Waiting for application deployments to be ready..."
kubectl wait --for=condition=available deployment --all -n $NAMESPACE --timeout=600s

if [ $? -eq 0 ]; then
    print_success "All deployments are ready!"
else
    print_error "Some deployments failed to become ready"
    kubectl get pods -n $NAMESPACE
    exit 1
fi

# Show deployment status
print_status "Final Deployment Status:"
echo ""
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE  
echo ""
kubectl get ingress -n $NAMESPACE

# Get access information
MINIKUBE_IP=$(minikube ip)

echo ""
echo "==============================="
echo "    DEPLOYMENT COMPLETED       "
echo "==============================="
echo ""
echo "Minikube IP: $MINIKUBE_IP"
echo ""
echo "Application URLs:"
echo "  Client UI:    http://pressnavek-appointment-app.gromosome.com"
echo "  Admin UI:     http://admin-pressnavek-appointment-app.gromosome.com"  
echo "  API Gateway:  http://api-pressnavek-appointment-app.gromosome.com"
echo ""
echo "Health Check URLs:"
echo "  User Service: http://api-pressnavek-appointment-app.gromosome.com/health"
echo "  Bot Service:  http://api-pressnavek-appointment-app.gromosome.com/bot/health"
echo ""
echo "Quick Test Commands:"
echo "  curl http://$MINIKUBE_IP/health"
echo "  curl http://$MINIKUBE_IP/bot/health"
echo ""
echo "Add to /etc/hosts for local testing:"
echo "$MINIKUBE_IP pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com"

# Logout from Docker Hub
docker logout

print_success "Docker Hub deployment completed successfully!"
print_status "Your application is now running on Minikube with images from Docker Hub"