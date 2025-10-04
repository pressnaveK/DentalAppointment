# Three-Host Architecture Documentation

This document explains the three-host architecture for the ChatAppointment application deployed on Minikube.

## Architecture Overview

The application is deployed across three separate hosts for better separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Minikube Cluster                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Client UI Host  │  │ Admin UI Host   │  │   API Host      │ │
│  │your-domain.com  │  │admin.your-      │  │api.your-        │ │
│  │                 │  │domain.com       │  │domain.com       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │         │
│           │                     │                     │         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Client UI     │  │    Admin UI     │  │  User Service   │ │
│  │   (React +      │  │   (React +      │  │   (NestJS)      │ │
│  │    Nginx)       │  │    Nginx)       │  │                 │ │
│  └─────────────────┘  └─────────────────┘  │                 │ │
│                                            │                 │ │
│                                            │  Bot Service    │ │
│                                            │   (FastAPI)     │ │
│                                            └─────────────────┘ │
│                                                     │         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   PostgreSQL    │  │     Redis       │  │   Persistent    │ │
│  │                 │  │                 │  │    Storage      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Host Configuration

### 1. Client UI Host
- **Domain**: `pressnavek-appointment-app.gromosome.com`
- **Service**: `client-ui` (React application)
- **Purpose**: Main user-facing application
- **Port**: 80
- **SSL**: Handled by ingress

### 2. Admin UI Host  
- **Domain**: `admin-pressnavek-appointment-app.gromosome.com`
- **Service**: `admin-ui` (React admin panel)
- **Purpose**: Administrative interface
- **Port**: 80
- **SSL**: Handled by ingress

### 3. API Host
- **Domain**: `api-pressnavek-appointment-app.gromosome.com`
- **Services**: Both `user-service` and `bot-service`
- **Purpose**: Unified API gateway
- **Routing**:
  - `/` → User Service (NestJS, port 3000)
  - `/bot/*` → Bot Service (FastAPI, port 8000)

## URL Structure

### Client UI (`pressnavek-appointment-app.gromosome.com`)
```
https://pressnavek-appointment-app.gromosome.com/
├── /                    → Home page
├── /login               → User login
├── /dashboard           → User dashboard
├── /appointments        → Appointment management
└── /profile             → User profile
```

### Admin UI (`admin-pressnavek-appointment-app.gromosome.com`)
```
https://admin-pressnavek-appointment-app.gromosome.com/
├── /                    → Admin dashboard
├── /users               → User management
├── /appointments        → Appointment management
├── /analytics           → Analytics dashboard
└── /settings            → System settings
```

### API Gateway (`api-pressnavek-appointment-app.gromosome.com`)
```
https://api-pressnavek-appointment-app.gromosome.com/
├── /health              → User Service health check
├── /auth/               → Authentication endpoints
│   ├── /auth/login      → User login
│   ├── /auth/register   → User registration
│   └── /auth/refresh    → Token refresh
├── /users/              → User management
│   ├── /users/profile   → User profile
│   └── /users/settings  → User settings
├── /appointments/       → Appointment management
└── /bot/                → Bot Service endpoints
    ├── /bot/health      → Bot Service health check
    ├── /bot/chat        → Chat with bot
    └── /bot/models      → Available AI models
```

## Environment Variables

### Frontend Applications

#### Client UI Environment
```bash
VITE_API_BASE_URL=https://api-pressnavek-appointment-app.gromosome.com
VITE_BOT_API_URL=https://api-pressnavek-appointment-app.gromosome.com/bot
```

#### Admin UI Environment
```bash
VITE_API_BASE_URL=https://api-pressnavek-appointment-app.gromosome.com
VITE_BOT_API_URL=https://api-pressnavek-appointment-app.gromosome.com/bot
```

### Backend Services

#### Internal Communication (Service-to-Service)
```bash
API_BASE_URL=http://user-service:3000
BOT_API_URL=http://bot-service:8000
DATABASE_URL=postgresql://chatuser:chatpass@postgres:5432/chatapp
REDIS_URL=redis://redis:6379
```

## Frontend API Calls

### From Client UI
```javascript
// User API calls
const response = await fetch('https://api-pressnavek-appointment-app.gromosome.com/users/profile', {
  headers: { 'Authorization': `Bearer ${token}` }
});

// Bot API calls
const chatResponse = await fetch('https://api-pressnavek-appointment-app.gromosome.com/bot/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: 'Hello' })
});
```

### From Admin UI
```javascript
// User management
const users = await fetch('https://api-pressnavek-appointment-app.gromosome.com/users');

// Bot configuration
const botConfig = await fetch('https://api-pressnavek-appointment-app.gromosome.com/bot/config');
```

## CORS Configuration

The ingress includes CORS headers to allow cross-origin requests:

```yaml
nginx.ingress.kubernetes.io/configuration-snippet: |
  more_set_headers "Access-Control-Allow-Origin: *";
  more_set_headers "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS";
  more_set_headers "Access-Control-Allow-Headers: Content-Type, Authorization";
```

## SSL/TLS Configuration

All three hosts share a single wildcard SSL certificate:

```yaml
tls:
- hosts:
  - api-pressnavek-appointment-app.gromosome.com
  - admin-pressnavek-appointment-app.gromosome.com
  - pressnavek-appointment-app.gromosome.com
  secretName: chat-appointment-tls
```

## Local Development Setup

### 1. Update /etc/hosts
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts
echo "$MINIKUBE_IP pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com" | sudo tee -a /etc/hosts
```

### 2. Access Applications
```bash
# Client UI
curl http://pressnavek-appointment-app.gromosome.com/

# Admin UI  
curl http://admin-pressnavek-appointment-app.gromosome.com/

# User API
curl http://api-pressnavek-appointment-app.gromosome.com/health

# Bot API
curl http://api-pressnavek-appointment-app.gromosome.com/bot/health
```

## Deployment Commands

### Initial Deployment
```bash
# Deploy everything
make minikube-start

# Check status
make minikube-status

# Get URLs
make minikube-urls
```

### Selective Updates
```bash
# Update only changed services
make minikube-deploy

# Update specific service
./scripts/minikube-deploy.sh selective "api/bot_service/"
```

## Benefits of Three-Host Architecture

### 1. **Clear Separation of Concerns**
- Client and Admin UIs are completely separate
- APIs are consolidated under one host
- Each has independent scaling and deployment

### 2. **Security Benefits**
- Admin UI on separate subdomain
- API endpoints consolidated for better security monitoring
- Clear access control boundaries

### 3. **Development Benefits**
- Frontend teams can work independently
- API versioning and routing simplified
- Clear testing boundaries

### 4. **Operational Benefits**
- Independent SSL certificates if needed
- Separate monitoring and logging
- Independent scaling policies

### 5. **SEO and Branding**
- Clean URL structure
- Professional subdomains
- Better analytics separation

## Monitoring and Troubleshooting

### Health Checks
```bash
# Check all services
curl http://api-pressnavek-appointment-app.gromosome.com/health
curl http://api-pressnavek-appointment-app.gromosome.com/bot/health

# Check UI availability
curl -I http://pressnavek-appointment-app.gromosome.com/
curl -I http://admin-pressnavek-appointment-app.gromosome.com/
```

### Kubernetes Commands
```bash
# Check ingress status
kubectl describe ingress chat-appointment-ingress -n chat-appointment

# Check service endpoints
kubectl get endpoints -n chat-appointment

# View logs
kubectl logs -f deployment/user-service -n chat-appointment
kubectl logs -f deployment/bot-service -n chat-appointment
```

### Common Issues

#### 1. DNS Resolution
If hosts don't resolve, check `/etc/hosts`:
```bash
# Verify entries
grep pressnavek-appointment-app.gromosome.com /etc/hosts

# Re-add if missing
minikube ip | xargs -I {} echo "{} pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com" | sudo tee -a /etc/hosts
```

#### 2. CORS Errors
Check ingress CORS configuration:
```bash
kubectl get ingress chat-appointment-ingress -n chat-appointment -o yaml | grep -A 5 configuration-snippet
```

#### 3. Service Connectivity
Test internal service connectivity:
```bash
kubectl exec -it deployment/user-service -n chat-appointment -- curl http://bot-service:8000/health
```

## Production Considerations

### 1. Domain Configuration
- Purchase actual domains (e.g., `myapp.com`, `admin.myapp.com`, `api.myapp.com`)
- Configure DNS A records to point to your server IP
- Set up proper SSL certificates with Let's Encrypt

### 2. Security Enhancements
- Implement rate limiting per host
- Add authentication middleware for admin subdomain
- Use network policies to restrict internal communication

### 3. Performance Optimization
- Enable caching for static assets
- Implement CDN for frontend assets
- Configure proper HTTP/2 and compression

### 4. Monitoring
- Set up separate monitoring dashboards per host
- Implement health checks for each subdomain
- Configure alerting for each service type