# Adding New Applications

This guide explains how to add new applications to the ArgoCD bootstrap repository.

## Application Structure

Each application follows this structure in every environment:

```
environments/{env}/charts/{app-name}/
├── Chart.yaml              # Helm chart definition
├── values.yaml             # Environment-specific values
├── templates/              # Kubernetes manifests (optional)
└── pipeline/
    └── application.yaml    # ArgoCD Application definition
```

## Step-by-Step Guide

### 1. Create Application Structure

For each environment (dev, staging, prod), create the application structure:

```bash
# Example: Adding Prometheus
mkdir -p environments/dev/charts/prometheus/{templates,pipeline}
mkdir -p environments/staging/charts/prometheus/{templates,pipeline}
mkdir -p environments/prod/charts/prometheus/{templates,pipeline}
```

### 2. Create Chart.yaml

Create `Chart.yaml` for each environment:

```yaml
# environments/dev/charts/prometheus/Chart.yaml
apiVersion: v2
name: prometheus
description: Prometheus monitoring stack
type: application
version: 1.0.0
appVersion: "2.45.0"

dependencies:
  - name: kube-prometheus-stack
    version: 51.2.0
    repository: https://prometheus-community.github.io/helm-charts
```

### 3. Create values.yaml

Create environment-specific values:

```yaml
# environments/dev/charts/prometheus/values.yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      replicas: 1
      resources:
        requests:
          cpu: 100m
          memory: 512Mi
        limits:
          cpu: 500m
          memory: 1Gi
  
  grafana:
    enabled: true
    adminPassword: admin123
    
  alertmanager:
    enabled: false
```

### 4. Create ArgoCD Application

Create the pipeline application manifest:

```yaml
# environments/dev/charts/prometheus/pipeline/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus-dev
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  project: default
  source:
    repoURL: https://github.com/zeeemughal/example-argocd.git
    targetRevision: HEAD
    path: environments/dev/charts/prometheus
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
  revisionHistoryLimit: 3
```

### 5. Update Main Pipeline

Add the new application to the main pipeline kustomization:

```yaml
# environments/dev/main-pipeline/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../charts/cert-manager/pipeline/application.yaml
  - ../charts/nginx-ingress/pipeline/application.yaml
  - ../charts/argocd/pipeline/application.yaml
  - ../charts/prometheus/pipeline/application.yaml  # Add this line

commonLabels:
  environment: dev
  managed-by: argocd

patches:
  - path: patches/common-patches.yaml
    target:
      kind: Application
```

### 6. Repeat for All Environments

Repeat steps 2-5 for staging and production environments, adjusting:

- Application names (prometheus-staging, prometheus-prod)
- Source paths (environments/staging/charts/prometheus, environments/prod/charts/prometheus)
- Values for each environment
- Resource limits and replicas

## Environment-Specific Considerations

### Development
- Single replicas
- Lower resource limits
- Development-friendly configurations
- Auto-sync enabled

### Staging
- Production-like configuration
- Moderate resource allocation
- Good for testing

### Production
- High availability (multiple replicas)
- Production resource limits
- Security hardening
- Manual sync recommended

## Sync Waves

Use sync waves to control deployment order:

- **Wave 1**: Infrastructure (cert-manager, ingress)
- **Wave 2**: ArgoCD self-management
- **Wave 3**: Monitoring (Prometheus, Grafana)
- **Wave 4**: Application dependencies
- **Wave 5+**: Applications

## Best Practices

1. **Consistent Naming**: Use `{app-name}-{environment}` pattern
2. **Resource Limits**: Always set appropriate limits
3. **Health Checks**: Configure proper health checks
4. **Dependencies**: Use sync waves for dependencies
5. **Secrets**: Use external secret management
6. **Testing**: Test in dev before promoting to staging/prod

## Example: Complete Prometheus Setup

See the `examples/` directory for complete application examples including:
- Prometheus monitoring stack
- External DNS
- Sealed Secrets
- Istio service mesh
