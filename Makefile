.PHONY: help build test lint clean dev prod deploy setup

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Setup development environment
setup: ## Setup development environment
	@echo "Setting up development environment..."
	@cp .env.example .env
	@echo "Please update .env file with your configuration"
	@bazel version || echo "Please install Bazel: https://bazel.build/install"

# Build targets
build: ## Build all changed services using Bazel
	@./scripts/selective-build.sh build

build-all: ## Build all services
	@bazel build //...

build-images: ## Build all Docker images
	@bazel build //:all_images

# Development
dev: ## Start development environment with Docker Compose
	@docker-compose up --build

dev-detached: ## Start development environment in detached mode
	@docker-compose up --build -d

# Production
prod: ## Start production environment
	@docker-compose -f docker-compose.prod.yml up --build -d

# Testing
test: ## Run tests for changed services
	@./scripts/selective-build.sh test

test-all: ## Run all tests
	@bazel test //...

# Linting
lint: ## Run linting for changed services
	@./scripts/selective-build.sh lint

lint-all: ## Run linting for all services
	@bazel run //:all_lint

# Individual service commands
bot-service: ## Build bot service
	@bazel build //api/bot_service:bot_service_image

user-service: ## Build user service
	@bazel build //api/user_service:user_service_image

admin-ui: ## Build admin UI
	@bazel build //ui/admin_ui:admin_ui_image

client-ui: ## Build client UI
	@bazel build //ui/client_ui:client_ui_image

# Docker commands
docker-build: ## Build all Docker images using docker-compose
	@docker-compose build

docker-push: ## Push all Docker images
	@echo "Pushing Docker images..."
	@docker-compose push

# Database commands
db-migrate: ## Run database migrations
	@docker-compose exec user-service npm run migration:run

db-seed: ## Seed database with initial data
	@docker-compose exec user-service npm run seed

# Cleanup
clean: ## Clean build artifacts
	@bazel clean
	@docker system prune -f

clean-all: ## Clean everything including Docker volumes
	@bazel clean --expunge
	@docker-compose down -v
	@docker system prune -a -f

# Logs
logs: ## Show logs from all services
	@docker-compose logs -f

logs-bot: ## Show bot service logs
	@docker-compose logs -f bot-service

logs-user: ## Show user service logs
	@docker-compose logs -f user-service

logs-admin: ## Show admin UI logs
	@docker-compose logs -f admin-ui

logs-client: ## Show client UI logs
	@docker-compose logs -f client-ui

# Status
status: ## Show status of all services
	@docker-compose ps

# Minikube deployment commands
minikube-start: ## Start Minikube cluster
	@./scripts/minikube-deploy.sh deploy

minikube-deploy: ## Deploy to Minikube (selective)
	@./scripts/selective-build.sh deploy

minikube-status: ## Show Minikube deployment status
	@./scripts/minikube-deploy.sh status

minikube-urls: ## Show access URLs
	@./scripts/minikube-deploy.sh urls

minikube-destroy: ## Destroy Minikube deployment
	@./scripts/minikube-deploy.sh destroy

minikube-hosts: ## Setup /etc/hosts entries for three-host architecture
	@./scripts/setup-hosts.sh

# Deploy (customize for your deployment target)
deploy: ## Deploy to Minikube
	@./scripts/minikube-deploy.sh deploy

# Security scan
security-scan: ## Run security scan on Docker images
	@echo "Running security scans..."
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image chat-appointment_bot-service:latest
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image chat-appointment_user-service:latest

# Performance test
perf-test: ## Run performance tests
	@echo "Running performance tests..."
	@echo "Implement your performance testing here"