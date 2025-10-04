# ChatAppointment - Domain Configuration

## Your Custom Domains

This project is configured for your specific gromosome.com domains:

### 🌐 Production Domains
- **Client UI**: `pressnavek-appointment-app.gromosome.com`
- **Admin UI**: `admin-pressnavek-appointment-app.gromosome.com`  
- **API Gateway**: `api-pressnavek-appointment-app.gromosome.com`

### 🚀 Quick Start Commands

```bash
# 1. Deploy to Minikube
make minikube-start

# 2. Setup hosts file (maps domains to Minikube IP)
make minikube-hosts

# 3. Verify deployment
make minikube-status

# 4. Get access URLs
make minikube-urls
```

### 🔗 Access URLs (After Setup)

**Main Applications:**
- Client App: http://pressnavek-appointment-app.gromosome.com
- Admin Panel: http://admin-pressnavek-appointment-app.gromosome.com

**API Endpoints:**
- User API: http://api-pressnavek-appointment-app.gromosome.com/
- Bot API: http://api-pressnavek-appointment-app.gromosome.com/bot/
- Health Checks:
  - http://api-pressnavek-appointment-app.gromosome.com/health
  - http://api-pressnavek-appointment-app.gromosome.com/bot/health

### 🧪 Test Commands

```bash
# Test all endpoints
curl http://pressnavek-appointment-app.gromosome.com/
curl http://admin-pressnavek-appointment-app.gromosome.com/
curl http://api-pressnavek-appointment-app.gromosome.com/health
curl http://api-pressnavek-appointment-app.gromosome.com/bot/health
```

### 📝 Manual Hosts Setup (Alternative)

If the automated script doesn't work, manually add to `/etc/hosts`:

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts
echo "$MINIKUBE_IP pressnavek-appointment-app.gromosome.com admin-pressnavek-appointment-app.gromosome.com api-pressnavek-appointment-app.gromosome.com" | sudo tee -a /etc/hosts
```

### 🔧 Environment Variables

The following environment variables are configured for your domains:

```bash
# Frontend apps will use these API URLs
VITE_API_BASE_URL=https://api-pressnavek-appointment-app.gromosome.com
VITE_BOT_API_URL=https://api-pressnavek-appointment-app.gromosome.com/bot

# For local development (HTTP)
VITE_API_BASE_URL_LOCAL=http://api-pressnavek-appointment-app.gromosome.com
VITE_BOT_API_URL_LOCAL=http://api-pressnavek-appointment-app.gromosome.com/bot
```

### 🏗️ Service Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           gromosome.com Domain Structure                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    pressnavek-appointment-app.gromosome.com                │ │
│  │                         (Client UI - React App)                            │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                admin-pressnavek-appointment-app.gromosome.com              │ │
│  │                      (Admin UI - React Admin Panel)                        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                 api-pressnavek-appointment-app.gromosome.com               │ │
│  │                           (API Gateway)                                    │ │
│  │  ┌─────────────────────────┐  ┌─────────────────────────────────────────┐  │ │
│  │  │      User Service       │  │          Bot Service                    │  │ │
│  │  │      (NestJS)           │  │         (FastAPI)                       │  │ │
│  │  │   All /api/* routes     │  │     All /api/bot/* routes               │  │ │
│  │  └─────────────────────────┘  └─────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 🔄 Development Workflow

1. **Make changes** to any service
2. **Deploy selectively**: `make minikube-deploy` (only rebuilds changed services)
3. **Test endpoints** using the URLs above
4. **Check logs**: `kubectl logs -f deployment/SERVICE_NAME -n chat-appointment`

### 📋 SSL/TLS Configuration

The ingress is configured with SSL for all three hosts:

```yaml
tls:
- hosts:
  - api-pressnavek-appointment-app.gromosome.com
  - admin-pressnavek-appointment-app.gromosome.com
  - pressnavek-appointment-app.gromosome.com
  secretName: chat-appointment-tls
```

For production, you'll need to:
1. Configure DNS A records to point to your server IP
2. Set up Let's Encrypt certificates
3. Update cert-manager configuration

### 🛠️ Troubleshooting

**Issue**: Domains don't resolve
```bash
# Solution: Check /etc/hosts
grep gromosome.com /etc/hosts
# If missing, run: make minikube-hosts
```

**Issue**: Service not responding
```bash
# Solution: Check pod status
kubectl get pods -n chat-appointment
kubectl describe pod POD_NAME -n chat-appointment
```

**Issue**: CORS errors
```bash
# Solution: Check ingress configuration
kubectl describe ingress chat-appointment-ingress -n chat-appointment
```