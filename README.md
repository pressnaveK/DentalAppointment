# ChatAppointment - Monorepo with Selective Building

This project is organized as a monorepo with multiple services and UIs, using Bazel for build orchestration and Docker for containerization. The selective build system ensures that only changed components are built and deployed.

## Architecture

```
ChatAppointment/
├── api/                    # Backend Services
│   ├── bot_service/       # Python FastAPI service
│   └── user_service/      # Node.js NestJS service
├── ui/                    # Frontend Applications
│   ├── admin_ui/          # React admin interface
│   └── client_ui/         # React client interface
├── scripts/               # Build and deployment scripts
├── platforms/             # Bazel platform definitions
└── .github/workflows/     # CI/CD pipelines
```

## Services

### Bot Service (Python/FastAPI)
- **Location**: `api/bot_service/`
- **Technology**: Python 3.11, FastAPI, LangChain
- **Port**: 8000
- **Purpose**: AI chatbot and appointment processing

### User Service (Node.js/NestJS)
- **Location**: `api/user_service/`
- **Technology**: Node.js 18, NestJS, TypeScript
- **Port**: 3000
- **Purpose**: User management and authentication

### Admin UI (React/Vite)
- **Location**: `ui/admin_ui/`
- **Technology**: React 19, TypeScript, Vite
- **Port**: 5173 (dev), 80 (prod)
- **Purpose**: Administrative interface

### Client UI (React/Vite)
- **Location**: `ui/client_ui/`
- **Technology**: React 19, TypeScript, Vite
- **Port**: 5174 (dev), 80 (prod)
- **Purpose**: Client-facing application

## Quick Start

### Prerequisites
- [Bazel](https://bazel.build/install) (for build orchestration)
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Node.js 18+](https://nodejs.org/) (for local development)
- [Python 3.11+](https://python.org/) (for local development)

### Setup

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd ChatAppointment
   make setup
   ```

2. **Start development environment**:
   ```bash
   make dev
   ```

3. **Access the applications**:
   - Bot Service: http://localhost:8000
   - User Service: http://localhost:3000
   - Admin UI: http://localhost:5173
   - Client UI: http://localhost:5174

## Minikube Deployment (Three-Host Architecture)

The application can be deployed to Minikube using a three-host architecture for better separation:

### Quick Minikube Setup
```bash
# Deploy to Minikube
make minikube-start

# Get access URLs
make minikube-urls
```

### Three-Host Structure
- **Client UI**: `pressnavek-appointment-app.gromosome.com` - Main user application
- **Admin UI**: `admin-pressnavek-appointment-app.gromosome.com` - Administrative interface  
- **API Gateway**: `api-pressnavek-appointment-app.gromosome.com` - Unified API endpoints
  - User API: `api-pressnavek-appointment-app.gromosome.com/`
  - Bot API: `api-pressnavek-appointment-app.gromosome.com/bot/`

See [DOMAIN-CONFIG.md](DOMAIN-CONFIG.md) for your specific domain configuration.

## Build System

### Bazel Configuration
The project uses Bazel for:
- Dependency management
- Build orchestration
- Testing coordination
- Docker image creation

### Selective Building
The selective build system automatically detects changes and builds only affected services:

```bash
# Build only changed services
make build

# Build specific service
make bot-service
make user-service
make admin-ui
make client-ui

# Build everything
make build-all
```

### Build Commands

```bash
# Using Make (recommended)
make build          # Build changed services
make test           # Test changed services
make lint           # Lint changed services
make clean          # Clean build artifacts

# Using Bazel directly
bazel build //...                           # Build everything
bazel build //api/bot_service:bot_service   # Build specific target
bazel test //...                            # Run all tests
bazel run //api/user_service:lint           # Run linting

# Using the selective build script
./scripts/selective-build.sh build          # Build changed
./scripts/selective-build.sh test           # Test changed
./scripts/selective-build.sh lint           # Lint changed
./scripts/selective-build.sh all            # Do everything
```

## Docker Configuration

### Development
- Multi-stage builds with hot reloading
- Volume mounts for live code updates
- Separate containers for each service
- Shared network for inter-service communication

### Production
- Optimized multi-stage builds
- Security-hardened images
- Health checks
- Resource limits

### Commands
```bash
# Development
make dev              # Start all services
make dev-detached     # Start in background

# Production
make prod             # Start production environment

# Individual services
docker-compose up bot-service
docker-compose up user-service
docker-compose up admin-ui
docker-compose up client-ui

# Logs
make logs            # All services
make logs-bot        # Bot service only
make logs-user       # User service only
```

## CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Detects Changes**: Uses path filters to identify changed services
2. **Builds Selectively**: Only builds affected components
3. **Runs Tests**: Executes tests for changed services
4. **Creates Images**: Builds and pushes Docker images
5. **Deploys**: Deploys to staging/production (customize as needed)

### Workflow Triggers
- Push to `main` or `develop` branches
- Pull requests to `main`

### Change Detection
- `api/bot_service/**` → Builds bot service
- `api/user_service/**` → Builds user service  
- `ui/admin_ui/**` → Builds admin UI
- `ui/client_ui/**` → Builds client UI
- `WORKSPACE`, `.bazelrc`, `**/BUILD` → Builds all services

## Development Workflow

### Adding New Features
1. Create feature branch
2. Make changes to specific service(s)
3. Run tests: `make test`
4. Create pull request
5. CI automatically builds and tests only changed services

### Local Development
```bash
# Start specific service for development
cd api/user_service
npm run start:dev

# Or use Docker Compose for full environment
make dev

# Run tests for specific service
cd api/user_service
npm test

# Or use Bazel
bazel test //api/user_service:test
```

## Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/chatapp

# Redis
REDIS_URL=redis://localhost:6379

# APIs
API_BASE_URL=http://localhost:3000
BOT_API_URL=http://localhost:8000

# External Services
OPENAI_API_KEY=your-key-here
```

## Deployment

### Staging
Automatically deploys on pushes to `develop` branch.

### Production
Automatically deploys on pushes to `main` branch.

### Manual Deployment
```bash
# Build production images
make build-images

# Deploy to your environment
make deploy  # Customize for your needs
```

## Troubleshooting

### Common Issues

1. **Bazel build fails**:
   ```bash
   bazel clean
   bazel build //...
   ```

2. **Docker build issues**:
   ```bash
   make clean
   make docker-build
   ```

3. **Port conflicts**:
   - Check if ports 3000, 5173, 5174, 8000 are available
   - Modify docker-compose.yml if needed

4. **Permission issues**:
   ```bash
   chmod +x scripts/selective-build.sh
   ```

### Performance Optimization

1. **Bazel caching**: Uses local and remote caching
2. **Docker layer caching**: Multi-stage builds optimize layers
3. **Selective building**: Only builds changed components
4. **Parallel builds**: Services build in parallel when possible

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test: `make test`
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Create Pull Request

## Monitoring and Logs

```bash
# View all logs
make logs

# View specific service logs
make logs-bot
make logs-user
make logs-admin
make logs-client

# Check service status
make status
```

## Security

- All Docker images run as non-root users
- Security headers configured in Nginx
- Health checks for all services
- Vulnerability scanning in CI/CD

## License

[Your License Here]