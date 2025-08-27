# ArgoCD Beginner's Guide

This guide explains how ArgoCD works and how this repository implements GitOps patterns for managing Kubernetes applications.

## What is ArgoCD?

ArgoCD is a **GitOps** tool that automatically deploys applications to Kubernetes by watching Git repositories. Instead of manually running `kubectl apply`, ArgoCD:

1. **Watches** your Git repository for changes
2. **Compares** what's in Git vs what's running in Kubernetes
3. **Syncs** the differences automatically
4. **Maintains** the desired state continuously

## Key Concepts

### 1. GitOps Workflow
```
Developer → Git Push → ArgoCD Detects → Kubernetes Updated
```

### 2. Kustomize
**Kustomize** is a tool that lets you customize Kubernetes YAML files without modifying the original files. Think of it as "configuration management for Kubernetes manifests."

#### How Kustomize Works
```
Base YAML + Customizations = Final YAML
```

#### Key Kustomize Concepts:
- **kustomization.yaml**: The main file that tells Kustomize what to do
- **Resources**: List of YAML files to include
- **Patches**: Modifications to apply to resources
- **CommonLabels**: Labels to add to all resources
- **Transformers**: Advanced modifications

#### Example kustomization.yaml:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:                    # Files to include
  - app1.yaml
  - app2.yaml

commonLabels:                 # Add these labels to everything
  environment: dev
  managed-by: argocd

patches:                      # Modify specific resources
  - path: patches/dev-patch.yaml
    target:
      kind: Application
```

#### Why We Use Kustomize in This Repository:
1. **Environment Differences**: Same app, different configs per environment
2. **DRY Principle**: Don't repeat YAML, just customize what's different
3. **ArgoCD Integration**: ArgoCD natively understands Kustomize
4. **Patch Management**: Easy to apply environment-specific changes

### 3. ArgoCD Application
### 3. ArgoCD Application
An **Application** in ArgoCD is a configuration that tells ArgoCD:
- **Where** to find your code (Git repo + path)
- **What** Kubernetes cluster to deploy to
- **How** to sync (automatic vs manual)

Example:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://github.com/zeeemughal/example-argocd.git
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
```

### 4. App-of-Apps Pattern
Instead of creating many Applications manually, you create **one Application that creates other Applications**. This is called the "App-of-Apps" pattern.

## How This Repository Works

### Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repo      │    │     ArgoCD       │    │   Kubernetes    │
│                 │    │                  │    │                 │
│ 1. Root Pipeline├────┤ 2. Creates       ├────┤ 3. Deploys      │
│    application  │    │    Main-Pipelines│    │    Applications │
│                 │    │                  │    │                 │
│ 4. Main-Pipeline├────┤ 5. Creates       ├────┤ 6. Deploys      │
│    kustomization│    │    App Applications│   │    Workloads    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Step-by-Step Flow

#### 1. Bootstrap Phase (Manual - One Time Only)
```bash
# Install ArgoCD itself
kubectl apply -k bootstrap/argocd/

# Create the root pipeline Application
kubectl apply -f pipeline/application.yaml
```

#### 2. Root Pipeline (ArgoCD Managed)
The root pipeline (`pipeline/application.yaml`) creates ArgoCD Applications for each environment's main-pipeline:
- `main-pipeline-dev`
- `main-pipeline-staging` 
- `main-pipeline-prod`

#### 3. Main-Pipeline (ArgoCD Managed)
Each main-pipeline (`environments/{env}/main-pipeline/kustomization.yaml`) creates ArgoCD Applications for individual apps:
- `cert-manager-dev`
- `nginx-ingress-dev`
- `argocd-dev`

#### 4. Individual Apps (ArgoCD Managed)
Each app Application deploys the actual Kubernetes workloads (pods, services, etc.)

## Repository Structure Explained

```
argocd-bootstrap/
├── bootstrap/argocd/              # 🚀 Initial ArgoCD installation (manual)
├── pipeline/                      # 📋 Root pipeline (App-of-Apps)
│   ├── application.yaml          #     Creates main-pipeline Applications
│   └── kustomization.yaml        #     Lists all main-pipeline Applications
├── environments/
│   └── dev/
│       ├── charts/                # 📦 Individual application charts
│       │   ├── cert-manager/
│       │   │   ├── Chart.yaml    #     Helm chart definition
│       │   │   ├── values.yaml   #     Environment-specific config
│       │   │   └── pipeline/
│       │   │       └── application.yaml  # ArgoCD Application for cert-manager
│       │   └── nginx-ingress/     #     (same structure)
│       └── main-pipeline/         # 🎯 Orchestrates all dev apps
│           ├── kustomization.yaml #     Lists all app Applications
│           └── patches/           #     Environment-specific patches
```

## Sync Waves Explained

**Sync Waves** control the order of deployment using annotations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

**Our Deployment Order:**
- **Wave -1**: Root pipeline (creates main-pipelines)
- **Wave 0**: Main-pipelines (create app Applications)  
- **Wave 1**: Infrastructure apps (cert-manager, nginx-ingress)
- **Wave 2**: ArgoCD self-management
- **Wave 3+**: Additional applications

This ensures dependencies are deployed in the correct order.

## Kustomize Deep Dive

Since this repository heavily uses Kustomize, let's understand how it works in our context.

### What Problems Does Kustomize Solve?

**Problem**: You have the same application but need different configurations for dev/staging/prod.

**Bad Solution**: Copy-paste YAML files and modify each one
- Hard to maintain
- Easy to make mistakes
- Changes need to be applied to multiple files

**Kustomize Solution**: One base configuration + environment-specific patches
- Single source of truth
- Easy to maintain
- Clear separation of concerns

### Kustomize in Our Repository

#### 1. Main-Pipeline Kustomization
```yaml
# environments/dev/main-pipeline/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:                                    # List all ArgoCD Applications
  - ../charts/cert-manager/pipeline/application.yaml
  - ../charts/nginx-ingress/pipeline/application.yaml
  - ../charts/argocd/pipeline/application.yaml

commonLabels:                                 # Add to all Applications
  environment: dev
  managed-by: argocd

patches:                                      # Modify Applications
  - path: patches/common-patches.yaml
    target:
      kind: Application
```

**What this does:**
1. **Collects** all individual app ArgoCD Applications
2. **Adds** common labels to identify the environment
3. **Applies** patches for environment-specific settings

#### 2. Root Pipeline Kustomization
```yaml
# pipeline/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:                                    # List all main-pipeline Applications
  - ../environments/dev/main-pipeline/pipeline/application.yaml
  - ../environments/staging/main-pipeline/pipeline/application.yaml
  - ../environments/prod/main-pipeline/pipeline/application.yaml

commonLabels:                                 # Add to all main-pipelines
  managed-by: argocd
  pipeline-type: main
```

**What this does:**
1. **Collects** all environment main-pipeline Applications
2. **Creates** the App-of-Apps structure
3. **Manages** all environments from one place

### Kustomize Patches Explained

**Patches** let you modify resources without changing the original files.

#### JSON Patch Format
```yaml
# environments/dev/main-pipeline/patches/common-patches.yaml
- op: add                                     # Operation: add, replace, remove
  path: /metadata/labels/environment          # Where to apply
  value: dev                                  # What to add

- op: add
  path: /spec/syncPolicy/retry               # Add retry policy
  value:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

#### Strategic Merge Patch (Alternative)
```yaml
# Alternative patch format
metadata:
  labels:
    environment: dev
spec:
  syncPolicy:
    retry:
      limit: 5
```

### Kustomize Commands (For Testing)

```bash
# Preview what Kustomize will generate
kustomize build environments/dev/main-pipeline/

# Apply directly (what ArgoCD does internally)
kustomize build environments/dev/main-pipeline/ | kubectl apply -f -

# Validate kustomization.yaml syntax
kustomize build environments/dev/main-pipeline/ --dry-run
```

### Environment Differences with Kustomize

Here's how we handle different environments:

#### Development Environment
```yaml
# environments/dev/main-pipeline/patches/common-patches.yaml
- op: add
  path: /metadata/labels/environment
  value: dev
- op: add
  path: /spec/syncPolicy/retry
  value:
    limit: 5                                  # More retries for dev
    backoff:
      duration: 5s                            # Faster retries
```

#### Production Environment
```yaml
# environments/prod/main-pipeline/patches/common-patches.yaml
- op: add
  path: /metadata/labels/environment
  value: prod
- op: replace
  path: /spec/syncPolicy/automated
  value:
    prune: true
    selfHeal: false                           # Manual healing in prod
- op: add
  path: /spec/syncPolicy/retry
  value:
    limit: 3                                  # Fewer retries
    backoff:
      duration: 10s                           # Slower, more careful
```

### Kustomize Best Practices

#### 1. Keep Patches Small and Focused
```yaml
# Good: Specific, clear patches
- op: add
  path: /spec/syncPolicy/automated/selfHeal
  value: false

# Bad: Large, complex patches that are hard to understand
```

#### 2. Use Descriptive Patch Files
```
patches/
├── common-patches.yaml          # Environment-wide settings
├── resource-limits.yaml         # Resource adjustments
└── security-patches.yaml       # Security-specific changes
```

#### 3. Validate Your Kustomizations
```bash
# Always test before committing
kustomize build environments/dev/main-pipeline/ > /tmp/output.yaml
kubectl apply --dry-run=client -f /tmp/output.yaml
```

#### 4. Use Comments in kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # Core infrastructure applications
  - ../charts/cert-manager/pipeline/application.yaml
  - ../charts/nginx-ingress/pipeline/application.yaml
  
  # ArgoCD self-management
  - ../charts/argocd/pipeline/application.yaml
```

### Troubleshooting Kustomize Issues

#### Common Error: "resource not found"
```bash
# Check if the resource path exists
ls -la environments/dev/charts/cert-manager/pipeline/application.yaml
```

#### Common Error: "patch failed"
```bash
# Validate patch syntax
kustomize build environments/dev/main-pipeline/ --load-restrictor=none
```

#### Common Error: "duplicate resource"
```bash
# Check for duplicate entries in resources list
grep -n "application.yaml" environments/dev/main-pipeline/kustomization.yaml
```

### Kustomize vs Helm

You might wonder why we use both Kustomize and Helm:

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **Helm** | Package and template Kubernetes apps | Installing third-party apps (nginx, cert-manager) |
| **Kustomize** | Customize and patch existing YAML | Environment-specific configurations, ArgoCD Applications |

**In our repository:**
- **Helm**: Installs nginx-ingress, cert-manager, ArgoCD (the actual workloads)
- **Kustomize**: Manages ArgoCD Applications and environment differences

This combination gives us the best of both worlds:
- **Helm** for complex application packaging
- **Kustomize** for simple, declarative customizations

## Adding a New Application - Complete Walkthrough

Let's add **Prometheus** to the dev environment:

### Step 1: Create the Chart Structure
```bash
mkdir -p environments/dev/charts/prometheus/{templates,pipeline}
```

### Step 2: Create Chart.yaml
```yaml
# environments/dev/charts/prometheus/Chart.yaml
apiVersion: v2
name: prometheus
description: Prometheus monitoring
version: 1.0.0
dependencies:
  - name: kube-prometheus-stack
    version: 51.2.0
    repository: https://prometheus-community.github.io/helm-charts
```

### Step 3: Create values.yaml
```yaml
# environments/dev/charts/prometheus/values.yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      replicas: 1
  grafana:
    enabled: true
```

### Step 4: Create ArgoCD Application
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
  source:
    repoURL: https://github.com/zeeemughal/example-argocd.git
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
```

### Step 5: Add to Main-Pipeline (Kustomize)
```yaml
# environments/dev/main-pipeline/kustomization.yaml
resources:
  - ../charts/cert-manager/pipeline/application.yaml
  - ../charts/nginx-ingress/pipeline/application.yaml
  - ../charts/argocd/pipeline/application.yaml
  - ../charts/prometheus/pipeline/application.yaml  # ← Add this line
```

**What happens here:**
- Kustomize will include the new Prometheus Application
- When ArgoCD syncs the main-pipeline, it will create the Prometheus Application
- The Prometheus Application will then deploy Prometheus itself

### Step 5.1: Test Your Kustomization (Optional but Recommended)
```bash
# Preview what will be created
kustomize build environments/dev/main-pipeline/

# Look for your new application in the output
kustomize build environments/dev/main-pipeline/ | grep "name: prometheus-dev"
```

### Step 6: Commit and Push
```bash
git add .
git commit -m "Add Prometheus monitoring to dev environment"
git push
```

### Step 7: Watch ArgoCD Work! 🎉
- ArgoCD detects the change in Git
- Main-pipeline syncs and creates the new `prometheus-dev` Application
- The `prometheus-dev` Application deploys Prometheus to the cluster
- **No manual kubectl commands needed!**

## Understanding Sync Policies

### Automatic Sync
```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Fix manual changes
```
- **Best for**: Development environments
- **Behavior**: ArgoCD automatically applies changes from Git

### Manual Sync
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: false  # Don't auto-fix manual changes
```
- **Best for**: Production environments
- **Behavior**: Changes require manual approval in ArgoCD UI

## Common ArgoCD Operations

### Check Application Status
```bash
# List all applications
kubectl get applications -n argocd

# Get detailed status
kubectl describe application prometheus-dev -n argocd
```

### Force Sync an Application
```bash
# Via CLI
argocd app sync prometheus-dev

# Via kubectl
kubectl patch application prometheus-dev -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{"force":true}}}}}'
```

### Access ArgoCD UI
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
```

## Troubleshooting Common Issues

### ArgoCD Issues

#### Application Stuck in "Progressing"
**Cause**: Resource not becoming healthy
**Solution**: Check the actual Kubernetes resources
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

#### Application Shows "OutOfSync"
**Cause**: Difference between Git and cluster
**Solution**: Check what's different
```bash
argocd app diff prometheus-dev
```

#### Sync Fails with Permission Error
**Cause**: ArgoCD doesn't have permissions
**Solution**: Check RBAC and service account permissions

#### Application Not Appearing
**Cause**: Main-pipeline hasn't synced yet
**Solution**: Check main-pipeline status
```bash
kubectl get application main-pipeline-dev -n argocd
```

### Kustomize Issues

#### "resource not found" Error
**Cause**: Path in kustomization.yaml is wrong
**Solution**: Verify the file exists
```bash
# Check if the path is correct
ls -la environments/dev/charts/prometheus/pipeline/application.yaml

# Check your kustomization.yaml paths
cat environments/dev/main-pipeline/kustomization.yaml
```

#### "duplicate resource" Error
**Cause**: Same resource listed twice in kustomization.yaml
**Solution**: Check for duplicates
```bash
# Look for duplicate entries
grep -n "prometheus" environments/dev/main-pipeline/kustomization.yaml
```

#### Patch Not Applied
**Cause**: Patch target doesn't match or patch syntax is wrong
**Solution**: Test the kustomization
```bash
# Build and check output
kustomize build environments/dev/main-pipeline/ > /tmp/test.yaml
grep -A 10 -B 5 "prometheus-dev" /tmp/test.yaml
```

#### "invalid patch" Error
**Cause**: JSON patch syntax is incorrect
**Solution**: Validate patch format
```yaml
# Correct format
- op: add
  path: /metadata/labels/environment
  value: dev

# Wrong format (missing 'op')
- path: /metadata/labels/environment
  value: dev
```

### Combined ArgoCD + Kustomize Issues

#### Main-Pipeline Shows OutOfSync but Individual Apps Are Fine
**Cause**: Kustomization.yaml changed but main-pipeline hasn't synced
**Solution**: Force sync the main-pipeline
```bash
kubectl patch application main-pipeline-dev -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{"force":true}}}}}'
```

#### New Application Added but Not Deployed
**Cause**: Added to Git but main-pipeline hasn't detected it
**Solution**: Check the sync chain
```bash
# 1. Check if main-pipeline is synced
kubectl get application main-pipeline-dev -n argocd

# 2. Check if new application was created
kubectl get application prometheus-dev -n argocd

# 3. If application exists, check its status
kubectl describe application prometheus-dev -n argocd
```

## Best Practices for Beginners

### 1. Start Small
- Begin with one environment (dev)
- Add one application at a time
- Test thoroughly before adding more

### 2. Use Sync Waves
- Always set appropriate sync waves
- Infrastructure first, applications second

### 3. Test Kustomizations Locally
```bash
# Always test before pushing
kustomize build environments/dev/main-pipeline/ > /tmp/test.yaml
kubectl apply --dry-run=client -f /tmp/test.yaml
```

### 4. Monitor ArgoCD
- Check ArgoCD UI regularly
- Set up notifications for sync failures

### 5. Environment Promotion
- Test in dev first
- Promote to staging, then production
- Use different sync policies per environment

### 6. Git Hygiene
- Use meaningful commit messages
- Create pull requests for production changes
- Tag releases for production deployments

### 7. Kustomize Organization
- Keep patches small and focused
- Use descriptive file names
- Comment your kustomization.yaml files
- Validate changes before committing

## What Happens When You Push Code?

Let's trace through what happens when you add a new application:

1. **You push** code to Git with a new application
2. **ArgoCD detects** the change (polls every 3 minutes by default)
3. **Main-pipeline syncs** and sees the new application in kustomization.yaml
4. **Kustomize processes** the kustomization.yaml and includes the new Application
5. **ArgoCD creates** the new Application resource in Kubernetes
6. **New Application syncs** and deploys your workload
7. **Everything is running** - no manual intervention needed!

**The Kustomize Role:**
- **Step 3-4**: Kustomize combines all the individual Application YAML files
- **Applies patches**: Environment-specific modifications
- **Adds labels**: Common labels for organization
- **Generates final YAML**: That ArgoCD then applies to Kubernetes

This is the power of GitOps + Kustomize - **Git becomes your single source of truth** and **Kustomize handles environment differences** automatically.

## Next Steps

1. **Deploy the repository** following the Quick Start guide
2. **Explore the ArgoCD UI** to see applications and their status
3. **Add your first application** following the walkthrough above
4. **Set up monitoring** to track application health
5. **Implement proper CI/CD** with automated testing before Git pushes

Welcome to GitOps! 🚀
