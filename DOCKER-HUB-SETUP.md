# Docker Hub Integration Setup Guide

## Required GitHub Secrets

You need to add these secrets to your GitHub repository for Docker Hub integration:

### 1. DOCKER_HUB_USERNAME
- **Description**: Your Docker Hub username
- **Example**: `pressnavek` or `yourDockerHubUsername`
- **Where to find**: Your Docker Hub profile URL: https://hub.docker.com/u/[USERNAME]

### 2. DOCKER_HUB_PASSWORD  
- **Description**: Your Docker Hub password (the one you use to login)
- **Security Note**: This is your actual Docker Hub password, not an access token
- **Alternative**: You can also use Access Tokens instead of passwords (recommended for better security)

### 3. VPS_HOST (Existing)
- **Value**: `62.169.25.53`

### 4. VPS_PASSWORD (Existing)
- **Value**: Your VPS password for user `pressnave`

## How to Add GitHub Secrets

1. Go to your GitHub repository: https://github.com/pressnaveK/DentalAppointment
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the exact name and value

## Docker Hub Repositories

The workflow will automatically create these repositories in your Docker Hub account:
- `{username}/chat-appointment-bot-service`
- `{username}/chat-appointment-user-service`
- `{username}/chat-appointment-admin-ui`
- `{username}/chat-appointment-client-ui`

**Note**: These will be created as **public repositories** by default. If you need private repositories, you'll need a Docker Hub Pro/Team subscription.

## New Deployment Architecture

### GitHub Actions (CI/CD):
1. **Build Phase**: Builds Docker images for changed services
2. **Push Phase**: Pushes images to Docker Hub with `latest` and commit SHA tags
3. **Deploy Phase**: Connects to VPS using sparse checkout

### VPS Deployment:
1. **Sparse Checkout**: Only clones `k8s/` and `scripts/` directories (not entire repo)
2. **Docker Hub Pull**: Pulls latest images from Docker Hub
3. **Image Tagging**: Tags Docker Hub images with local names for Kubernetes
4. **Kubernetes Deploy**: Applies manifests and waits for readiness

## Advantages of This Setup

✅ **Lightweight VPS**: Only contains deployment files, not source code  
✅ **Cloud Building**: All compilation happens in GitHub Actions  
✅ **Image Registry**: Docker Hub serves as central image repository  
✅ **Fast Deployments**: No local building, just pull and deploy  
✅ **Version Control**: Images tagged with commit SHAs for rollback capability  

## Verification Steps

After setting up the secrets:

1. **Push to main branch** to trigger the workflow
2. **Check GitHub Actions logs** for successful Docker Hub login and push
3. **Check Docker Hub** for your new repositories
4. **Verify VPS deployment** completes successfully
5. **Test application endpoints** are accessible

## Troubleshooting

### Docker Hub Login Issues:
- Verify `DOCKER_HUB_USERNAME` is correct (case-sensitive)
- Verify `DOCKER_HUB_PASSWORD` is your actual password
- Check if 2FA is enabled (may require access tokens instead)

### Image Pull Issues:
- Ensure images exist in Docker Hub after successful build
- Check image names match the expected format
- Verify Docker Hub repositories are public (or login is working)

### VPS Issues:
- Ensure Docker is installed and running
- Check Minikube is accessible
- Verify sparse checkout is working (only k8s/ and scripts/ should exist)

## Security Best Practices

- Consider using Docker Hub Access Tokens instead of passwords
- Keep Docker Hub repositories private if handling sensitive data
- Regularly rotate Docker Hub credentials
- Monitor Docker Hub for unauthorized access