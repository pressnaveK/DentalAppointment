#!/bin/bash

# Quick test script for ChatAppointment deployment
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

# Test if pods are running
test_pods() {
    print_status "Checking pod status..."
    kubectl get pods -n chat-appointment
    
    # Check if all pods are running
    NOT_RUNNING=$(kubectl get pods -n chat-appointment --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    if [ "$NOT_RUNNING" -eq 0 ]; then
        print_success "All pods are running!"
    else
        print_error "$NOT_RUNNING pods are not running"
        kubectl get pods -n chat-appointment --field-selector=status.phase!=Running
    fi
}

# Test health endpoints
test_health_endpoints() {
    print_status "Testing health endpoints..."
    
    # Get Minikube IP
    MINIKUBE_IP=$(minikube ip)
    
    # Test User Service health
    if curl -f -s "http://$MINIKUBE_IP/health" > /dev/null; then
        print_success "User Service health endpoint is working"
    else
        print_error "User Service health endpoint failed"
    fi
    
    # Test Bot Service health
    if curl -f -s "http://$MINIKUBE_IP/bot/health" > /dev/null; then
        print_success "Bot Service health endpoint is working"
    else
        print_error "Bot Service health endpoint failed"
    fi
    
    # Test Admin UI health
    if curl -f -s "http://$MINIKUBE_IP/admin/health" > /dev/null; then
        print_success "Admin UI health endpoint is working"
    else
        print_error "Admin UI health endpoint failed"
    fi
    
    # Test Client UI health
    if curl -f -s "http://$MINIKUBE_IP/health" > /dev/null; then
        print_success "Client UI health endpoint is working"
    else
        print_error "Client UI health endpoint failed"
    fi
}

# Test ingress configuration
test_ingress() {
    print_status "Testing ingress configuration..."
    kubectl describe ingress chat-appointment-ingress -n chat-appointment
}

# Show service endpoints
show_endpoints() {
    print_status "Service endpoints:"
    kubectl get services -n chat-appointment
    echo ""
    
    MINIKUBE_IP=$(minikube ip)
    echo "Access URLs:"
    echo "  Client UI:    http://$MINIKUBE_IP/"
    echo "  Admin UI:     http://$MINIKUBE_IP/admin/"
    echo "  User API:     http://$MINIKUBE_IP/"
    echo "  Bot API:      http://$MINIKUBE_IP/bot/"
    echo ""
    echo "Health checks:"
    echo "  curl http://$MINIKUBE_IP/health"
    echo "  curl http://$MINIKUBE_IP/bot/health"
    echo "  curl http://$MINIKUBE_IP/admin/health"
}

# Show recent logs
show_logs() {
    print_status "Recent logs from all services:"
    
    for deployment in bot-service user-service admin-ui client-ui; do
        echo "=== $deployment logs ==="
        kubectl logs deployment/$deployment -n chat-appointment --tail=10 2>/dev/null || echo "No logs available for $deployment"
        echo ""
    done
}

# Main test function
run_tests() {
    echo "==============================="
    echo "  ChatAppointment Test Suite   "
    echo "==============================="
    echo ""
    
    test_pods
    echo ""
    
    test_health_endpoints
    echo ""
    
    show_endpoints
    echo ""
    
    print_status "Ingress status:"
    kubectl get ingress -n chat-appointment
    echo ""
}

# Main script logic
case "${1:-test}" in
    "test")
        run_tests
        ;;
    "pods")
        test_pods
        ;;
    "health")
        test_health_endpoints
        ;;
    "ingress")
        test_ingress
        ;;
    "logs")
        show_logs
        ;;
    "endpoints")
        show_endpoints
        ;;
    *)
        echo "Usage: $0 {test|pods|health|ingress|logs|endpoints}"
        echo ""
        echo "Commands:"
        echo "  test       - Run all tests (default)"
        echo "  pods       - Check pod status"
        echo "  health     - Test health endpoints"
        echo "  ingress    - Show ingress configuration"
        echo "  logs       - Show recent logs"
        echo "  endpoints  - Show service endpoints"
        exit 1
        ;;
esac