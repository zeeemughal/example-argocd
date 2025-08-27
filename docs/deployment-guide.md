# Deployment Guide

This guide walks you through deploying the ArgoCD bootstrap repository.

## Prerequisites

- Kubernetes cluster (1.24+)
- kubectl configured to access your cluster
- Helm 3.x installed (for bootstrap only)

## Step 1: Bootstrap ArgoCD

First, install ArgoCD using the bootstrap configuration:

```bash
# Clone the repository
git clone https://github.com/your-org/argocd-bootstrap.git
cd argocd-bootstrap

# Install ArgoCD
kubectl apply -k bootstrap/argocd/
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Step 2: Access ArgoCD UI

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Port forward to access the UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD at: https://localhost:8080
- Username: `admin`
- Password: (from the command above)

## Step 3: Deploy Environment Applications

### Development Environment

```bash
kubectl apply -k environments/dev/main-pipeline/
```

### Staging Environment

```bash
kubectl apply -k environments/staging/main-pipeline/
```

### Production Environment

```bash
kubectl apply -k environments/prod/main-pipeline/
```

## Step 4: Verify Deployments

Check ArgoCD applications:

```bash
kubectl get applications -n argocd
```

Check application status:

```bash
# For development
kubectl get pods -n cert-manager
kubectl get pods -n ingress-nginx
kubectl get pods -n argocd

# Repeat for staging/prod namespaces if using different namespaces
```

## Sync Waves

Applications are deployed in the following order:

1. **Wave 1**: Infrastructure (cert-manager, nginx-ingress)
2. **Wave 2**: ArgoCD self-management
3. **Wave 3+**: Additional applications

## Troubleshooting

### ArgoCD Application Not Syncing

```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Force sync
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{"force":true}}}}}'
```

### Check Application Logs

```bash
# ArgoCD controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server
```

## Environment Differences

### Development
- Single replicas
- Insecure mode
- Local domains
- Auto-sync enabled

### Staging
- Similar to dev but with staging domains
- Good for testing production-like configs

### Production
- Multiple replicas
- TLS enabled
- Real domains
- Manual sync (selfHeal disabled)
- Resource limits enforced
