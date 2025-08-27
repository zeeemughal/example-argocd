# Quick Start Guide

## Repository Structure Created ✅

```
argocd-bootstrap/
├── README.md                           # Main documentation
├── QUICKSTART.md                       # This file
├── bootstrap/
│   └── argocd/                        # Initial ArgoCD installation
├── pipeline/                          # Root pipeline (App-of-Apps)
│   ├── kustomization.yaml            # Manages all main-pipelines
│   └── application.yaml              # Root ArgoCD application
├── environments/
│   ├── dev/                           # Development environment
│   │   ├── charts/                   # Helm-based apps
│   │   │   ├── argocd/               # Self-managed ArgoCD
│   │   │   ├── cert-manager/         # Certificate management
│   │   │   ├── nginx-ingress/        # Ingress controller
│   │   │   └── cluster-issuer/       # Let's Encrypt issuers
│   │   ├── deployments/              # Deployment-based apps
│   │   │   └── echo-app/             # Test echo application
│   │   └── main-pipeline/            # Orchestrates all dev apps
│   │       └── pipeline/             # ArgoCD app for main-pipeline
│   ├── staging/                       # Staging environment
│   └── prod/                         # Production environment
└── docs/                             # Detailed documentation
```

## What's Included

### Infrastructure Applications (Helm Charts)
- **ArgoCD**: Self-managed GitOps controller
- **Cert-Manager**: SSL certificate automation
- **Nginx Ingress**: Ingress controller for HTTP/HTTPS traffic
- **Cluster Issuer**: Let's Encrypt certificate issuers

### Test Applications (Deployments)
- **Echo App**: Test application with SSL/TLS certificates

### Domain Structure
- **Dev**: `*.dev.ithut.net` (Let's Encrypt staging)
- **Staging**: `*.stg.ithut.net` (Let's Encrypt staging)
- **Production**: `*.live.ithut.net` (Let's Encrypt production)

### Features
- ✅ Separate pipelines for each application
- ✅ Environment-specific configurations (dev/staging/prod)
- ✅ Values stay with charts
- ✅ Main pipeline orchestrates all apps using Kustomize
- ✅ Sync waves for proper deployment order
- ✅ Production-ready configurations
- ✅ SSL/TLS with Let's Encrypt certificates
- ✅ Real domain structure (ithut.net)
- ✅ Both Helm charts and plain deployments supported

## Quick Deploy

### Option 1: App-of-Apps Pattern (Recommended)
```bash
# 1. Bootstrap ArgoCD
kubectl apply -k bootstrap/argocd/

# 2. Deploy root pipeline (manages all environments)
kubectl apply -f pipeline/application.yaml
```

### Option 2: Individual Environment Deployment
```bash
# 1. Bootstrap ArgoCD
kubectl apply -k bootstrap/argocd/

# 2. Deploy specific environment
kubectl apply -k environments/dev/main-pipeline/
```

### 3. Access Applications
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward (for local access)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Application URLs (after DNS setup):**
- ArgoCD Dev: https://argocd.dev.ithut.net
- Echo App Dev: https://echo.dev.ithut.net
- ArgoCD Staging: https://argocd.stg.ithut.net
- Echo App Staging: https://echo.stg.ithut.net
- ArgoCD Prod: https://argocd.live.ithut.net
- Echo App Prod: https://echo.live.ithut.net

**Local Access:** https://localhost:8080 (admin / password-from-above)

## Next Steps

1. **New to ArgoCD?** Read the [ArgoCD Beginner's Guide](docs/argocd-beginner-guide.md) first
2. **Update Repository URLs**: Replace `https://github.com/your-org/argocd-bootstrap.git` in all application.yaml files
3. **Customize Domains**: Update domain names in ArgoCD values.yaml files
4. **Add Applications**: Follow [docs/adding-applications.md](docs/adding-applications.md)
5. **Deploy Other Environments**: Apply staging/prod when ready

## Key Features

### Separate Pipelines
Each app has its own ArgoCD Application in `{app}/pipeline/application.yaml`

### Environment Isolation
Complete separation between dev/staging/prod with different:
- Resource limits
- Replica counts
- Domain names
- Sync policies

### Main Pipeline Orchestration
Each environment's `main-pipeline/kustomization.yaml` lists all applications:
```yaml
resources:
  - ../charts/cert-manager/pipeline/application.yaml
  - ../charts/nginx-ingress/pipeline/application.yaml
  - ../charts/argocd/pipeline/application.yaml
```

### Sync Waves
- Wave 1: Infrastructure (cert-manager, nginx-ingress)
- Wave 2: ArgoCD self-management
- Wave 3+: Additional applications

Ready to go! 🚀
