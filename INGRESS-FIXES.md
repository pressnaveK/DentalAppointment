# Ingress Configuration Fixes

## Issues Resolved

The ingress configuration had several problems that have been fixed:

### 1. Deprecated Annotation
- **Issue**: `kubernetes.io/ingress.class: "nginx"` is deprecated
- **Fix**: Replaced with `spec.ingressClassName: nginx`

### 2. Path Type Incompatibility  
- **Issue**: Regex paths `(.*)` cannot be used with `pathType: Prefix`
- **Fix**: Split into two ingresses:
  - Bot service: Uses `pathType: ImplementationSpecific` for regex `/bot/(.*)`
  - Main services: Uses `pathType: Prefix` for simple paths

### 3. Configuration Snippet Disabled
- **Issue**: `nginx.ingress.kubernetes.io/configuration-snippet` is disabled by admin
- **Fix**: Replaced with built-in CORS annotations:
  - `nginx.ingress.kubernetes.io/enable-cors: "true"`
  - `nginx.ingress.kubernetes.io/cors-allow-origin: "*"`
  - `nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"`
  - `nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization"`

## New Ingress Structure

The ingress is now split into two resources:

### 1. Bot Service Ingress (`bot-service-ingress`)
- Handles `/bot/*` paths with rewrite to remove `/bot` prefix
- Uses regex pattern matching for proper path rewriting
- Routes to bot-service on port 8000

### 2. Main Application Ingress (`chat-appointment-ingress`)  
- Handles all other paths for three hosts:
  - `api-pressnavek-appointment-app.gromosome.com` → user-service
  - `admin-pressnavek-appointment-app.gromosome.com` → admin-ui
  - `pressnavek-appointment-app.gromosome.com` → client-ui

## URL Routing

After the fix, the routing works as follows:

```
api-pressnavek-appointment-app.gromosome.com/
├── /bot/health → bot-service:8000/health
├── /bot/chat → bot-service:8000/chat  
├── /bot/* → bot-service:8000/*
└── /* → user-service:3000/*

admin-pressnavek-appointment-app.gromosome.com/* → admin-ui:80/*

pressnavek-appointment-app.gromosome.com/* → client-ui:80/*
```

## Deployment Commands

To apply the fixed ingress configuration:

```bash
# Apply the updated ingress
kubectl apply -f k8s/07-ingress.yaml

# Check ingress status
kubectl get ingress -n chat-appointment

# Verify the ingress is working
kubectl describe ingress bot-service-ingress -n chat-appointment
kubectl describe ingress chat-appointment-ingress -n chat-appointment

# Test the endpoints
curl -k https://api-pressnavek-appointment-app.gromosome.com/health
curl -k https://api-pressnavek-appointment-app.gromosome.com/bot/health
```

## Expected Results

- No more deprecation warnings
- No more path type errors
- No more configuration snippet errors
- Proper SSL termination and CORS handling
- Bot service accessible at `/bot/*` paths
- All other services accessible at their respective hosts

## Troubleshooting

If you still see issues:

1. **Check ingress controller logs**:
   ```bash
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

2. **Verify ingress class**:
   ```bash
   kubectl get ingressclass
   ```

3. **Test without SSL first**:
   ```bash
   curl http://api-pressnavek-appointment-app.gromosome.com/health
   ```

4. **Check service endpoints**:
   ```bash
   kubectl get endpoints -n chat-appointment
   ```