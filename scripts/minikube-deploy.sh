#!/bin/bash

# Minikube setup and deployment script for ChatAppointment
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if minikube is installed
check_minikube() {
    if ! command -v minikube &> /dev/null; then
        print_error "Minikube is not installed. Please install it first."
        echo "Installation instructions: https://minikube.sigs.k8s.io/docs/start/"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
}

# Start minikube with appropriate resources
start_minikube() {
    print_status "Starting Minikube..."
    
    # Check if minikube is already running
    if minikube status &> /dev/null; then
        print_warning "Minikube is already running"
    else
        # Start minikube with sufficient resources
        minikube start \
            --cpus=4 \
            --memory=4096 \
            --disk-size=20g \
            --driver=docker \
            --kubernetes-version=v1.28.0
    fi
    
    # Enable required addons
    print_status "Enabling Minikube addons..."
    minikube addons enable ingress
    minikube addons enable registry
    minikube addons enable dashboard
    minikube addons enable metrics-server
    
    print_success "Minikube started successfully"
}

# Setup local registry
setup_registry() {
    print_status "Setting up local registry..."
    
    # Port forward registry (run in background)
    kubectl port-forward --namespace kube-system service/registry 5000:80 &
    REGISTRY_PID=$!
    echo $REGISTRY_PID > /tmp/registry-port-forward.pid
    
    # Wait for port forward to be ready
    sleep 5
    
    print_success "Registry is available at localhost:5000"
}

# Build and push images to minikube registry
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Configure docker to use minikube's docker daemon
    eval $(minikube docker-env)
    
    # Build images with minikube's docker
    print_status "Building bot-service image..."
    docker build -t localhost:5000/chat-appointment/bot-service:latest ./api/bot_service/
    
    print_status "Building user-service image..."
    docker build -t localhost:5000/chat-appointment/user-service:latest ./api/user_service/
    
    print_status "Building admin-ui image..."
    docker build -t localhost:5000/chat-appointment/admin-ui:latest ./ui/admin_ui/
    
    print_status "Building client-ui image..."
    docker build -t localhost:5000/chat-appointment/client-ui:latest ./ui/client_ui/
    
    # Push images to local registry
    print_status "Pushing images to local registry..."
    docker push localhost:5000/chat-appointment/bot-service:latest
    docker push localhost:5000/chat-appointment/user-service:latest
    docker push localhost:5000/chat-appointment/admin-ui:latest
    docker push localhost:5000/chat-appointment/client-ui:latest
    
    print_success "All images built and pushed successfully"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Apply Kubernetes manifests in order
    kubectl apply -f k8s/00-namespace-config.yaml
    kubectl apply -f k8s/01-storage.yaml
    kubectl apply -f k8s/02-database.yaml
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n chat-appointment --timeout=300s
    kubectl wait --for=condition=ready pod -l app=redis -n chat-appointment --timeout=300s
    
    # Deploy services
    kubectl apply -f k8s/03-bot-service.yaml
    kubectl apply -f k8s/04-user-service.yaml
    kubectl apply -f k8s/05-admin-ui.yaml
    kubectl apply -f k8s/06-client-ui.yaml
    kubectl apply -f k8s/07-ingress.yaml
    
    # Wait for deployments to be ready
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment --all -n chat-appointment --timeout=300s
    
    print_success "Deployment completed successfully"
}

# Get access URLs
get_access_urls() {
    print_status "Getting access URLs..."
    
    # Get minikube IP
    MINIKUBE_IP=$(minikube ip)
    
    echo ""
    echo "==============================="
    echo "    THREE-HOST ARCHITECTURE    "
    echo "==============================="
    echo ""
    echo "Minikube IP: $MINIKUBE_IP"
    echo ""
    echo "Application URLs (Three Separate Hosts):"
    echo "  Client UI:    http://pressnavek-appointment-app.gromosome.com"
    echo "  Admin UI:     http://admin-pressnavek-appointment-app.gromosome.com"
    echo "  API Gateway:  http://api-pressnavek-appointment-app.gromosome.com"
    echo ""
    echo "API Endpoints:"
    echo "  User API:     http://api-pressnavek-appointment-app.gromosome.com/"
    echo "  Bot API:      http://api-pressnavek-appointment-app.gromosome.com/bot/"
    echo ""
    echo "Health Check URLs:"
    echo "  User Service: http://api-pressnavek-appointment-app.gromosome.com/health"
    echo "  Bot Service:  http://api-pressnavek-appointment-app.gromosome.com/bot/health"
    echo ""
    echo "Quick Test Commands:"
    echo "  curl http://pressnavek-appointment-app.gromosome.com/"
    echo "  curl http://admin-pressnavek-appointment-app.gromosome.com/"
    echo "  curl http://api-pressnavek-appointment-app.gromosome.com/health"
    echo "  curl http://api-pressnavek-appointment-app.gromosome.com/bot/health"
    echo ""
    echo "Kubernetes Dashboard:"
    echo "  minikube dashboard"
    echo ""
    echo "Registry:"
    echo "  localhost:5000"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods -n chat-appointment"
    echo "  kubectl logs -f deployment/bot-service -n chat-appointment"
    echo "  kubectl logs -f deployment/user-service -n chat-appointment"
    echo "  kubectl describe ingress chat-appointment-ingress -n chat-appointment"
    echo ""
    
    # Add hosts entry suggestion
    echo "Add to /etc/hosts file for local development:"
    echo "$MINIKUBE_IP pressnavek-appointment-app.gromosome.com"
    echo "$MINIKUBE_IP admin-pressnavek-appointment-app.gromosome.com"
    echo "$MINIKUBE_IP api-pressnavek-appointment-app.gromosome.com"
    echo ""
    echo "Or use the quick command:"
    echo "echo '$MINIKUBE_IP pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com' | sudo tee -a /etc/hosts"
    echo ""
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    # Kill registry port-forward if exists
    if [ -f /tmp/registry-port-forward.pid ]; then
        kill $(cat /tmp/registry-port-forward.pid) 2>/dev/null || true
        rm /tmp/registry-port-forward.pid
    fi
}

# Main deployment function
deploy() {
    print_status "Starting ChatAppointment deployment to Minikube..."
    
    check_minikube
    start_minikube
    setup_registry
    build_and_push_images
    deploy_to_kubernetes
    get_access_urls
    
    print_success "Deployment completed! Check the URLs above to access your application."
}

# Selective rebuild and redeploy
selective_deploy() {
    local changed_files="$1"
    local services_to_update=()
    
    print_status "Performing selective deployment..."
    
    # Configure docker to use minikube's docker daemon
    eval $(minikube docker-env)
    
    # Determine which services to update
    if echo "$changed_files" | grep -q "^api/bot_service/"; then
        services_to_update+=("bot-service")
        print_status "Bot service changes detected - rebuilding..."
        docker build -t localhost:5000/chat-appointment/bot-service:latest ./api/bot_service/
        docker push localhost:5000/chat-appointment/bot-service:latest
        kubectl rollout restart deployment/bot-service -n chat-appointment
    fi
    
    if echo "$changed_files" | grep -q "^api/user_service/"; then
        services_to_update+=("user-service")
        print_status "User service changes detected - rebuilding..."
        docker build -t localhost:5000/chat-appointment/user-service:latest ./api/user_service/
        docker push localhost:5000/chat-appointment/user-service:latest
        kubectl rollout restart deployment/user-service -n chat-appointment
    fi
    
    if echo "$changed_files" | grep -q "^ui/admin_ui/"; then
        services_to_update+=("admin-ui")
        print_status "Admin UI changes detected - rebuilding..."
        docker build -t localhost:5000/chat-appointment/admin-ui:latest ./ui/admin_ui/
        docker push localhost:5000/chat-appointment/admin-ui:latest
        kubectl rollout restart deployment/admin-ui -n chat-appointment
    fi
    
    if echo "$changed_files" | grep -q "^ui/client_ui/"; then
        services_to_update+=("client-ui")
        print_status "Client UI changes detected - rebuilding..."
        docker build -t localhost:5000/chat-appointment/client-ui:latest ./ui/client_ui/
        docker push localhost:5000/chat-appointment/client-ui:latest
        kubectl rollout restart deployment/client-ui -n chat-appointment
    fi
    
    if [ ${#services_to_update[@]} -gt 0 ]; then
        print_status "Waiting for rollout to complete..."
        for service in "${services_to_update[@]}"; do
            kubectl rollout status deployment/$service -n chat-appointment --timeout=300s
        done
        print_success "Selective deployment completed for: ${services_to_update[*]}"
    else
        print_warning "No services need updating"
    fi
}

# Destroy everything
destroy() {
    print_status "Destroying ChatAppointment deployment..."
    
    kubectl delete namespace chat-appointment --ignore-not-found=true
    
    print_warning "To completely clean up, run: minikube delete"
    print_success "Deployment destroyed"
}

# Show status
status() {
    print_status "ChatAppointment deployment status:"
    echo ""
    kubectl get all -n chat-appointment
    echo ""
    print_status "Pod logs (recent):"
    kubectl get pods -n chat-appointment --no-headers | while read pod rest; do
        echo "--- $pod ---"
        kubectl logs $pod -n chat-appointment --tail=5 2>/dev/null || echo "No logs available"
        echo ""
    done
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "selective")
        if [ -z "$2" ]; then
            print_error "Usage: $0 selective <changed-files>"
            exit 1
        fi
        selective_deploy "$2"
        ;;
    "destroy")
        destroy
        ;;
    "status")
        status
        ;;
    "urls")
        get_access_urls
        ;;
    *)
        echo "Usage: $0 {deploy|selective|destroy|status|urls}"
        echo ""
        echo "Commands:"
        echo "  deploy     - Full deployment to Minikube"
        echo "  selective  - Selective deployment based on changes"
        echo "  destroy    - Remove all deployments"
        echo "  status     - Show deployment status"
        echo "  urls       - Show access URLs"
        exit 1
        ;;
esac

# Cleanup on exit
trap cleanup EXIT