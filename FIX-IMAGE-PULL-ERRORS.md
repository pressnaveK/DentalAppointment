# Fix for ErrImageNeverPull Issues

## Problem

Your Kubernetes pods are failing with `ErrImageNeverPull` errors because:

1. **Images don't exist**: The Docker images `chat-appointment/*:latest` are not present in Minikube's Docker daemon
2. **Pull policy**: The manifests use `imagePullPolicy: Never`, which means Kubernetes won't try to pull images from a registry
3. **CI/CD didn't run**: The images weren't built and loaded into Minikube during the last deployment

## Quick Fix (Run on VPS)

SSH to your VPS and run the automated fix script:

```bash
# SSH to VPS
ssh pressnave@62.169.25.53

# Navigate to project directory
cd /home/pressnave/ChatAppointment

# Pull latest changes
git pull origin main

# Run the fix script
./scripts/fix-image-pull.sh
```

## Manual Fix (Alternative)

If you prefer to run the commands manually:

```bash
# SSH to VPS
ssh pressnave@62.169.25.53
cd /home/pressnave/ChatAppointment

# Configure Docker to use Minikube's daemon
eval $(minikube docker-env)

# Build all images
docker build -t chat-appointment/bot-service:latest ./api/bot_service/
docker build -t chat-appointment/user-service:latest ./api/user_service/
docker build -t chat-appointment/admin-ui:latest ./ui/admin_ui/
docker build -t chat-appointment/client-ui:latest ./ui/client_ui/

# Verify images are built
docker images | grep chat-appointment

# Restart deployments
kubectl rollout restart deployment --all -n chat-appointment

# Wait for deployments
kubectl wait --for=condition=available deployment --all -n chat-appointment --timeout=300s

# Check status
kubectl get pods -n chat-appointment
```

## Why This Happened

1. **Image Names Changed**: We switched from `localhost:5000/chat-appointment/*` to `chat-appointment/*`
2. **Pull Policy Changed**: We changed from `Always` to `Never` for local images
3. **Images Not Built**: The new image names weren't built in Minikube's Docker daemon yet

## Verification Commands

After running the fix, verify everything is working:

```bash
# Check pod status (all should be Running)
kubectl get pods -n chat-appointment

# Check deployments (all should be Available)
kubectl get deployments -n chat-appointment

# Test health endpoints
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP/health          # User service
curl http://$MINIKUBE_IP/bot/health      # Bot service

# Or test with domain names
curl http://api-pressnavek-appointment-app.gromosome.com/health
curl http://api-pressnavek-appointment-app.gromosome.com/bot/health
```

## Expected Results

After the fix:
- All pods should be in "Running" state
- No more `ErrImageNeverPull` errors
- Health endpoints should respond successfully
- Applications accessible via ingress

## Future Prevention

The next GitHub Actions CI/CD run should prevent this issue by:
1. Building images as Docker archives
2. Transferring them to the VPS
3. Loading them into Minikube's Docker daemon before deployment
4. Using the correct image names with `imagePullPolicy: Never`

## If Issues Persist

1. **Check Minikube status**: `minikube status`
2. **Check Docker daemon**: `eval $(minikube docker-env) && docker images`
3. **Check pod events**: `kubectl describe pod <pod-name> -n chat-appointment`
4. **Check service logs**: `kubectl logs deployment/<service-name> -n chat-appointment`