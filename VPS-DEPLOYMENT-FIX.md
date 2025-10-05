# VPS Deployment Troubleshooting Guide

## Issue: Image Pull Failures

The pods are failing to pull images because they're looking for `localhost:5000/chat-appointment/*` images, but the local registry isn't available.

## Solution Applied

1. **Updated Kubernetes Manifests**: Changed all image references from `localhost:5000/chat-appointment/*` to `chat-appointment/*`
2. **Changed Image Pull Policy**: Changed from `Always` to `Never` to use local images
3. **Updated CI/CD**: Modified deployment script to load images directly into Minikube's Docker daemon
4. **Removed Registry Dependency**: No longer requires a local Docker registry

## Quick Fix for Current VPS Deployment

If you're currently seeing the image pull errors, run these commands on the VPS:

```bash
# SSH into the VPS
ssh pressnave@62.169.25.53

# Navigate to project directory
cd /home/pressnave/ChatAppointment

# Pull latest changes
git fetch origin
git reset --hard origin/main

# Configure Docker to use Minikube's daemon
eval $(minikube docker-env)

# Build images directly in Minikube
docker build -t chat-appointment/bot-service:latest ./api/bot_service/
docker build -t chat-appointment/user-service:latest ./api/user_service/
docker build -t chat-appointment/admin-ui:latest ./ui/admin_ui/
docker build -t chat-appointment/client-ui:latest ./ui/client_ui/

# Verify images are built
docker images | grep chat-appointment

# Apply the updated Kubernetes manifests
kubectl apply -f k8s/

# Force restart all deployments to use new images
kubectl rollout restart deployment/bot-service -n chat-appointment
kubectl rollout restart deployment/user-service -n chat-appointment
kubectl rollout restart deployment/admin-ui -n chat-appointment
kubectl rollout restart deployment/client-ui -n chat-appointment

# Wait for deployments to be ready
kubectl wait --for=condition=available deployment --all -n chat-appointment --timeout=600s

# Check pod status
kubectl get pods -n chat-appointment

# Test the deployment
./scripts/test-deployment.sh
```

## Verification Commands

```bash
# Check if all pods are running
kubectl get pods -n chat-appointment

# Check deployment status
kubectl get deployments -n chat-appointment

# View recent events
kubectl get events -n chat-appointment --sort-by='.lastTimestamp'

# Check ingress
kubectl get ingress -n chat-appointment

# Test health endpoints
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP/health
curl http://$MINIKUBE_IP/bot/health
```

## Expected Results

After applying the fix:
- All pods should be in "Running" state
- No more "ImagePullBackOff" errors
- Health endpoints should respond
- Applications should be accessible via the ingress

## Next CI/CD Run

The next GitHub Actions run should deploy successfully without registry issues because:
1. Images are built and saved as artifacts
2. Images are loaded directly into Minikube's Docker daemon
3. No dependency on external registry
4. Uses `imagePullPolicy: Never` for local images

## Domain Access

Once deployed, the applications will be available at:
- Client UI: http://pressnavek-appointment-app.gromosome.com
- Admin UI: http://admin-pressnavek-appointment-app.gromosome.com  
- API: http://api-pressnavek-appointment-app.gromosome.com