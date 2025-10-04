# ChatAppointment - Minikube Deployment Guide

This guide covers deploying the ChatAppointment monorepo to Minikube on a VPS.

## Prerequisites

### VPS Requirements
- **CPU**: 4+ cores
- **RAM**: 8GB+ 
- **Storage**: 40GB+ free space
- **OS**: Ubuntu 20.04+ or similar Linux distribution
- **Network**: Public IP with ports 80, 443, and 22 accessible

### Required Software
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm (optional)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd ChatAppointment
make setup
```

### 2. Configure Environment
```bash
# Update Minikube environment
cp .env.minikube .env
# Edit .env with your actual API keys and configuration
nano .env
```

### 3. Deploy to Minikube
```bash
# Full deployment
make minikube-start

# Or use the direct script
./scripts/minikube-deploy.sh deploy
```

### 4. Access Applications
```bash
# Get access URLs
make minikube-urls

# Get Minikube IP
minikube ip
```

## Deployment Commands

### Initial Deployment
```bash
# Start Minikube and deploy everything
make minikube-start

# Check deployment status
make minikube-status

# Get access URLs
make minikube-urls
```

### Selective Deployment (after changes)
```bash
# Deploy only changed services
make minikube-deploy

# Or manually specify
./scripts/minikube-deploy.sh selective "api/bot_service/main.py ui/admin_ui/src/App.tsx"
```

### Management Commands
```bash
# Show status
kubectl get all -n chat-appointment

# View logs
kubectl logs -f deployment/bot-service -n chat-appointment
kubectl logs -f deployment/user-service -n chat-appointment

# Scale services
kubectl scale deployment bot-service --replicas=3 -n chat-appointment

# Update image (force pull)
kubectl patch deployment bot-service -n chat-appointment \
  -p '{"spec":{"template":{"metadata":{"annotations":{"date":"'$(date +'%s')'"}}}}}}'
```

## Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Minikube VPS                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Nginx      │    │   Admin UI  │    │  Client UI  │     │
│  │  Ingress    │────┤   (React)   │    │   (React)   │     │
│  │             │    └─────────────┘    └─────────────┘     │
│  └─────────────┘                                           │
│         │                                                  │
│  ┌─────────────┐    ┌─────────────┐                       │
│  │ User Service│    │ Bot Service │                       │
│  │  (NestJS)   │    │  (FastAPI)  │                       │
│  └─────────────┘    └─────────────┘                       │
│         │                   │                             │
│  ┌─────────────┐    ┌─────────────┐                       │
│  │ PostgreSQL  │    │    Redis    │                       │
│  │             │    │             │                       │
│  └─────────────┘    └─────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Accessing Services

### Internal Service URLs (within cluster)
- Bot Service: `http://bot-service:8000`
- User Service: `http://user-service:3000`
- PostgreSQL: `postgresql://chatuser:chatpass@postgres:5432/chatapp`
- Redis: `redis://redis:6379`

### External Access (via Minikube IP)
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access applications
echo "Client UI: http://$MINIKUBE_IP"
echo "Admin UI: http://admin.$MINIKUBE_IP"  # Add to /etc/hosts
echo "API: http://$MINIKUBE_IP/api"
echo "Bot API: http://$MINIKUBE_IP/api/bot"
```

### Domain Configuration
Add to your `/etc/hosts` file:
```bash
# Replace with your actual Minikube IP
192.168.49.2 localhost
192.168.49.2 admin.localhost
```

## Development Workflow

### 1. Local Development
```bash
# Develop locally with hot reload
make dev

# Test changes
make test
make lint
```

### 2. Deploy Changes
```bash
# Selective deployment (recommended)
make minikube-deploy

# Or full redeployment
make minikube-start
```

### 3. Monitor and Debug
```bash
# View real-time logs
kubectl logs -f deployment/bot-service -n chat-appointment

# Access dashboard
minikube dashboard

# Port forward for debugging
kubectl port-forward service/bot-service 8000:8000 -n chat-appointment
```

## Scaling and Performance

### Horizontal Scaling
```bash
# Scale individual services
kubectl scale deployment bot-service --replicas=3 -n chat-appointment
kubectl scale deployment user-service --replicas=3 -n chat-appointment

# Auto-scaling (HPA)
kubectl autoscale deployment bot-service --cpu-percent=80 --min=1 --max=5 -n chat-appointment
```

### Resource Management
```bash
# Check resource usage
kubectl top pods -n chat-appointment
kubectl top nodes

# Modify resource limits in k8s/*.yaml files
# Then apply changes:
kubectl apply -f k8s/03-bot-service.yaml
```

## Monitoring and Observability

### Built-in Monitoring
```bash
# Enable metrics server
minikube addons enable metrics-server

# View metrics
kubectl top pods -n chat-appointment
kubectl top nodes
```

### Dashboard Access
```bash
# Open Kubernetes dashboard
minikube dashboard

# Access from external network (VPS)
kubectl proxy --address='0.0.0.0' --disable-filter=true
# Access via: http://YOUR_VPS_IP:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Backup and Recovery

### Database Backup
```bash
# Backup PostgreSQL
kubectl exec -n chat-appointment $(kubectl get pods -n chat-appointment -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- pg_dump -U chatuser chatapp > backup.sql

# Restore PostgreSQL
kubectl exec -i -n chat-appointment $(kubectl get pods -n chat-appointment -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U chatuser chatapp < backup.sql
```

### Configuration Backup
```bash
# Backup all Kubernetes resources
kubectl get all -n chat-appointment -o yaml > backup.yaml

# Backup secrets and configmaps
kubectl get secrets,configmaps -n chat-appointment -o yaml > config-backup.yaml
```

## Troubleshooting

### Common Issues

#### 1. Pods not starting
```bash
# Check pod status
kubectl get pods -n chat-appointment

# Describe problematic pod
kubectl describe pod <pod-name> -n chat-appointment

# Check logs
kubectl logs <pod-name> -n chat-appointment
```

#### 2. Image pull failures
```bash
# Check if local registry is running
kubectl get pods -n kube-system | grep registry

# Restart registry port-forward
kubectl port-forward --namespace kube-system service/registry 5000:80 &
```

#### 3. Service connectivity issues
```bash
# Test service connectivity
kubectl exec -it <pod-name> -n chat-appointment -- nslookup postgres
kubectl exec -it <pod-name> -n chat-appointment -- curl http://user-service:3000/health
```

#### 4. Resource constraints
```bash
# Check node resources
kubectl describe nodes

# Free up space
minikube cache delete
docker system prune -a
```

### Health Checks
```bash
# Check all service health endpoints
curl http://$(minikube ip)/api/health
curl http://$(minikube ip)/api/bot/health
```

## Security Considerations

### Network Policies
The current setup allows all pod-to-pod communication. For production, implement network policies:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: chat-appointment
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Secrets Management
- Update default secrets in `k8s/00-namespace-config.yaml`
- Use external secret management for production
- Rotate JWT secrets regularly

### Resource Limits
All services have resource limits defined to prevent resource exhaustion.

## Production Considerations

1. **SSL/TLS**: Configure cert-manager for automatic SSL certificates
2. **Monitoring**: Deploy Prometheus and Grafana for comprehensive monitoring
3. **Logging**: Implement centralized logging with ELK stack
4. **Backup**: Automated backup solutions for data persistence
5. **Security**: Network policies, pod security policies, and regular updates

## Cleanup

### Partial Cleanup
```bash
# Remove deployment
make minikube-destroy

# Remove specific namespace
kubectl delete namespace chat-appointment
```

### Complete Cleanup
```bash
# Delete entire Minikube cluster
minikube delete

# Remove all Docker images
docker system prune -a
```