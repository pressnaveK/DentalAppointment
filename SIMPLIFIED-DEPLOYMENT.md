# Simplified Docker Hub Deployment

This document describes the simplified deployment approach where Kubernetes pulls images directly from Docker Hub.

## Overview

The deployment has been simplified to eliminate local Docker operations. Minikube pulls images directly from Docker Hub using the `pressnavek/` namespace.

## Architecture

```
GitHub Actions (CI/CD)
    ↓
    Build & Push to Docker Hub
    ↓
    Deploy to VPS (Sparse Checkout)
    ↓
    Minikube pulls directly from Docker Hub
```

## Docker Hub Images

All services are available as public images on Docker Hub:

- `pressnavek/chat-appointment-bot-service:latest`
- `pressnavek/chat-appointment-user-service:latest`
- `pressnavek/chat-appointment-admin-ui:latest`
- `pressnavek/chat-appointment-client-ui:latest`

## Kubernetes Configuration

All Kubernetes manifests use direct Docker Hub image references:

```yaml
containers:
- name: service-name
  image: pressnavek/chat-appointment-service-name:latest
  imagePullPolicy: Always
```

The `imagePullPolicy: Always` ensures Minikube always pulls the latest image from Docker Hub.

## Deployment Process

### 1. GitHub Actions (Automated)

The CI/CD pipeline automatically:
1. Builds all Docker images
2. Pushes images to Docker Hub
3. Deploys to VPS using sparse checkout
4. Applies Kubernetes manifests

### 2. Manual Deployment (VPS)

If deploying manually on the VPS:

```bash
# Clone only deployment files (sparse checkout already configured)
cd ChatAppointment

# Apply Kubernetes manifests
kubectl apply -f k8s/

# Or use the deployment script
./scripts/deploy-from-dockerhub.sh
```

## Key Benefits

1. **No Local Docker Operations**: Minikube handles all image pulling
2. **Always Latest**: `imagePullPolicy: Always` ensures fresh deployments
3. **Simplified Scripts**: No Docker login, pull, or tag operations needed
4. **Faster Deployment**: Direct image references eliminate intermediate steps
5. **Resource Efficient**: No local image storage required

## VPS Requirements

- Minikube running
- kubectl configured
- Internet access for Docker Hub
- Only `k8s/` and `scripts/` directories (sparse checkout)

## Troubleshooting

### Image Pull Errors

If you see image pull errors:

1. Check if images exist on Docker Hub:
   - https://hub.docker.com/r/pressnavek/chat-appointment-bot-service
   - https://hub.docker.com/r/pressnavek/chat-appointment-user-service
   - https://hub.docker.com/r/pressnavek/chat-appointment-admin-ui
   - https://hub.docker.com/r/pressnavek/chat-appointment-client-ui

2. Verify internet connectivity from Minikube:
   ```bash
   kubectl run test-pod --image=busybox --rm -it -- nslookup hub.docker.com
   ```

### Check Pod Status

```bash
kubectl get pods -n chat-appointment
kubectl describe pod <pod-name> -n chat-appointment
```

## URLs

After deployment, access the application at:

- Client UI: http://pressnavek-appointment-app.gromosome.com
- Admin UI: http://admin-pressnavek-appointment-app.gromosome.com
- API: http://api-pressnavek-appointment-app.gromosome.com

## Docker Hub Repository Structure

```
pressnavek/
├── chat-appointment-bot-service
├── chat-appointment-user-service
├── chat-appointment-admin-ui
└── chat-appointment-client-ui
```

Each repository contains the latest built image that Kubernetes pulls directly during deployment.