# Cloudflare Tunnel Ingress Controller

This chart deploys the Cloudflare Tunnel Ingress Controller in the Kubernetes cluster.

## Prerequisites

1. A Cloudflare account with API access
2. External Secrets Operator installed in the cluster
3. Cloudflare API token with necessary permissions
4. Cloudflare Account ID

## Installation

1. Store your Cloudflare credentials in your secret management system (e.g., AWS Secrets Manager, HashiCorp Vault):
   - `cloudflare/api-token`: Your Cloudflare API token
   - `cloudflare/account-id`: Your Cloudflare Account ID

2. Update the `values.yaml` with your configuration:
   ```yaml
   cloudflare:
     tunnelName: "your-tunnel-name"
     # Other configurations as needed
   ```

3. The chart will be automatically deployed by ArgoCD.

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cloudflare.apiToken` | Cloudflare API Token | `""` (set via ExternalSecret) |
| `cloudflare.accountId` | Cloudflare Account ID | `""` (set via ExternalSecret) |
| `cloudflare.tunnelName` | Name for the Cloudflare Tunnel | `"k8s-tunnel"` |
| `controller.replicaCount` | Number of controller replicas | `1` |
| `controller.image.repository` | Controller image repository | `ghcr.io/strrl/cloudflare-tunnel-ingress-controller` |
| `controller.image.tag` | Controller image tag | `v0.1.0` |

## Usage

After installation, you can create Ingress resources with the following annotations to use the Cloudflare Tunnel:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
  annotations:
    kubernetes.io/ingress.class: cloudflare-tunnel
    cloudflare-tunnel-ingress-controller.strrl.dev/tunnel: "true"
```

## Notes

- The controller requires a Cloudflare API token with the following permissions:
  - Account: Cloudflare Tunnel:Edit
  - Zone: DNS:Edit
  - Account: Cloudflare Tunnel:Read

- The tunnel will be automatically created if it doesn't exist.
