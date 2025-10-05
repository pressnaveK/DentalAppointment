#!/bin/bash

# VPS Setup Script for Chat Appointment Deployment
# This script prepares a VPS for Minikube deployment with CI/CD

set -e

echo "Setting up VPS for Chat Appointment deployment..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this script as root"
    echo "Run as the deployment user (pressnave)"
    exit 1
fi

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install kubectl
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed successfully"
else
    echo "kubectl already installed"
fi

# Install Minikube
echo "🚢 Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
    echo "Minikube installed successfully"
else
    echo "Minikube already installed"
fi

# Start Minikube
echo "Starting Minikube..."
if ! minikube status > /dev/null 2>&1; then
    minikube start --cpus=4 --memory=4096 --disk-size=20g --driver=docker
    echo "Minikube started successfully"
else
    echo "Minikube already running"
fi

# Enable required addons
echo "🔧 Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable registry
minikube addons enable metrics-server

# Configure Docker to use Minikube's Docker daemon
echo "🔧 Configuring Docker environment..."
eval $(minikube docker-env)

# Create project directory
echo "Creating project directory..."
mkdir -p /home/pressnave/ChatAppointment

# Ensure SSH password authentication is enabled
echo "Configuring SSH for password authentication..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
echo "SSH password authentication enabled"

# Configure host entries for local development
echo "Configuring host entries..."
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Add host entries to /etc/hosts
sudo tee -a /etc/hosts << EOF

# Chat Appointment Application Hosts
$MINIKUBE_IP admin-pressnavek-appointment-app.gromosome.com
$MINIKUBE_IP api-pressnavek-appointment-app.gromosome.com
$MINIKUBE_IP pressnavek-appointment-app.gromosome.com
EOF

# Create a script to update hosts when Minikube IP changes
cat > ~/update-hosts.sh << 'EOF'
#!/bin/bash
MINIKUBE_IP=$(minikube ip)
sudo sed -i '/# Chat Appointment Application Hosts/,+3d' /etc/hosts
sudo tee -a /etc/hosts << EOL

# Chat Appointment Application Hosts
$MINIKUBE_IP admin-pressnavek-appointment-app.gromosome.com
$MINIKUBE_IP api-pressnavek-appointment-app.gromosome.com
$MINIKUBE_IP pressnavek-appointment-app.gromosome.com
EOL
echo "Hosts updated with Minikube IP: $MINIKUBE_IP"
EOF

chmod +x ~/update-hosts.sh

# Configure firewall (UFW)
echo "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8080/tcp  # Minikube dashboard
    sudo ufw --force enable
    echo "Firewall configured"
fi

# Install additional tools
echo "Installing additional tools..."
sudo apt install -y git htop tree jq

# Create system service for Minikube auto-start
echo "Creating Minikube auto-start service..."
sudo tee /etc/systemd/system/minikube.service << EOF
[Unit]
Description=Minikube
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/minikube start --cpus=4 --memory=4096 --disk-size=20g --driver=docker
ExecStop=/usr/local/bin/minikube stop
User=pressnave
Group=pressnave
Environment=HOME=/home/pressnave

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable minikube

# Create backup script
echo "Creating backup script..."
cat > ~/backup-deployment.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/pressnave/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating backup for $DATE..."

# Backup Kubernetes resources
kubectl get all -n chat-appointment -o yaml > "$BACKUP_DIR/k8s-resources-$DATE.yaml"

# Backup persistent volumes
kubectl get pv,pvc -o yaml > "$BACKUP_DIR/persistent-volumes-$DATE.yaml"

# Backup Docker images
docker save -o "$BACKUP_DIR/docker-images-$DATE.tar" \
  $(docker images --format "table {{.Repository}}:{{.Tag}}" | grep chat-appointment | tr '\n' ' ')

echo "Backup completed: $BACKUP_DIR"
ls -la $BACKUP_DIR/*$DATE*
EOF

chmod +x ~/backup-deployment.sh

# Create monitoring script
echo "Creating monitoring script..."
cat > ~/monitor-deployment.sh << 'EOF'
#!/bin/bash

echo "=== Chat Appointment Deployment Status ==="
echo ""

# Minikube status
echo "Minikube Status:"
minikube status
echo ""

# Kubernetes nodes
echo "Kubernetes Nodes:"
kubectl get nodes
echo ""

# Pods status
echo "Pods Status:"
kubectl get pods -n chat-appointment
echo ""

# Services status
echo "Services Status:"
kubectl get services -n chat-appointment
echo ""

# Ingress status
echo "Ingress Status:"
kubectl get ingress -n chat-appointment
echo ""

# Resource usage
echo "Resource Usage:"
kubectl top nodes
kubectl top pods -n chat-appointment
echo ""

# Recent events
echo "Recent Events:"
kubectl get events -n chat-appointment --sort-by=.metadata.creationTimestamp | tail -10
EOF

chmod +x ~/monitor-deployment.sh

# Print summary
echo ""
echo "VPS setup completed successfully!"
echo ""
echo "Summary of installed components:"
echo "   Docker $(docker --version | cut -d' ' -f3)"
echo "   kubectl $(kubectl version --client --short | cut -d' ' -f3)"
echo "   Minikube $(minikube version | grep version | cut -d' ' -f3)"
echo "   Minikube IP: $(minikube ip)"
echo ""
echo "Available scripts:"
echo "   ~/monitor-deployment.sh - Monitor deployment status"
echo "   ~/backup-deployment.sh - Backup deployment"
echo "   ~/update-hosts.sh - Update host entries"
echo ""
echo "Important next steps:"
echo "   1. Set a strong password for the 'pressnave' user (if not already done)"
echo "   2. Configure GitHub secrets (VPS_PASSWORD)"
echo "   3. Test SSH connection with password authentication"
echo "   4. Run your first deployment"
echo ""
echo "To monitor the deployment:"
echo "   ./monitor-deployment.sh"
echo ""
echo "Documentation available in:"
echo "   - docs/deployment-guide.md"
echo "   - docs/github-secrets-setup.md"
echo ""

# Final checks
echo "Running final checks..."
docker info > /dev/null 2>&1 && echo "   Docker is running"
kubectl cluster-info > /dev/null 2>&1 && echo "   Kubernetes is accessible"
minikube status > /dev/null 2>&1 && echo "   Minikube is running"

echo ""
echo "VPS is ready for deployment!"