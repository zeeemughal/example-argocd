# Deployments

This folder contains deployment-based applications that use plain Kubernetes manifests instead of Helm charts.

## Structure

Each application follows this structure:
```
app-name/
├── kustomization.yaml      # Kustomize configuration
├── namespace.yaml          # Namespace definition
├── deployment.yaml         # Kubernetes Deployment
├── service.yaml           # Kubernetes Service
├── ingress.yaml           # Ingress configuration
└── pipeline/
    └── application.yaml   # ArgoCD Application
```

## Applications

### echo-app
- **Purpose**: Test application using echo-server
- **Image**: `ealen/echo-server:latest`
- **Domain**: `echo.dev.ithut.net`
- **Features**: 
  - SSL/TLS with Let's Encrypt
  - Health checks
  - Resource limits

## Adding New Deployment-Based Apps

1. Create the app directory structure
2. Add Kubernetes manifests (deployment, service, ingress, etc.)
3. Create kustomization.yaml
4. Create pipeline/application.yaml
5. Add to main-pipeline/kustomization.yaml

## Environment Differences

- **Dev**: Single replica, lower resources, staging certificates
- **Staging**: Similar to dev but with staging domain
- **Prod**: Multiple replicas, higher resources, production certificates, health checks
