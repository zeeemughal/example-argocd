# ArgoCD Bootstrap Repository

This repository contains the GitOps configuration for bootstrapping and managing applications across multiple environments using ArgoCD.

## Repository Structure

```
argocd-bootstrap/
├── bootstrap/                     # Initial ArgoCD installation
├── pipeline/                      # Root pipeline (manages main-pipelines)
├── environments/
│   ├── dev/                      # Development environment
│   │   ├── charts/               # Helm-based applications
│   │   ├── deployments/          # Deployment-based applications
│   │   └── main-pipeline/        # Orchestrates dev apps
│   │       └── pipeline/         # ArgoCD app for main-pipeline
│   ├── staging/                  # Staging environment
│   └── prod/                     # Production environment
└── docs/                         # Documentation
```

## Applications Managed

### Infrastructure (Helm Charts)
- **ArgoCD**: Self-managed ArgoCD installation
- **Nginx Ingress Controller**: Ingress management
- **Cert-Manager**: SSL certificate automation
- **Cluster Issuer**: Let's Encrypt certificate issuers

### Applications (Deployments)
- **Echo App**: Test application with SSL/TLS

## Domain Structure

- **Development**: `*.dev.ithut.net`
- **Staging**: `*.stg.ithut.net`
- **Production**: `*.live.ithut.net`

### Application URLs
- **ArgoCD Dev**: https://argocd.dev.ithut.net
- **ArgoCD Staging**: https://argocd.stg.ithut.net
- **ArgoCD Production**: https://argocd.live.ithut.net
- **Echo App Dev**: https://echo.dev.ithut.net
- **Echo App Staging**: https://echo.stg.ithut.net
- **Echo App Production**: https://echo.live.ithut.net

## Deployment Process

### 1. Bootstrap ArgoCD (One-time setup)
```bash
# Apply initial ArgoCD installation
kubectl apply -k bootstrap/argocd/
```

### 2. Deploy Root Pipeline (App-of-Apps Pattern)
```bash
# Deploy the root pipeline that manages all main-pipelines
kubectl apply -f pipeline/application.yaml
```

### 3. Alternative: Deploy Individual Environment Pipelines
```bash
# Deploy specific environment main-pipelines directly
kubectl apply -k environments/dev/main-pipeline/
kubectl apply -k environments/staging/main-pipeline/
kubectl apply -k environments/prod/main-pipeline/
```

## Adding New Applications

### Helm-based Applications (charts/)
1. Create chart structure in each environment: `environments/{env}/charts/{app-name}/`
2. Add Chart.yaml, values.yaml, and templates
3. Create pipeline/application.yaml for ArgoCD
4. Update main-pipeline/kustomization.yaml to include the new application

### Deployment-based Applications (deployments/)
1. Create deployment structure: `environments/{env}/deployments/{app-name}/`
2. Add Kubernetes manifests (deployment.yaml, service.yaml, ingress.yaml, etc.)
3. Create kustomization.yaml and pipeline/application.yaml
4. Update main-pipeline/kustomization.yaml to include the new application

## Environment-Specific Configuration

Each environment has its own:
- Chart values (values.yaml per chart)
- ArgoCD Application configurations
- Main pipeline orchestration

## Documentation

- [ArgoCD Beginner's Guide](docs/argocd-beginner-guide.md) - **Start here if you're new to ArgoCD**
- [Deployment Guide](docs/deployment-guide.md)
- [Adding New Applications](docs/adding-applications.md)
