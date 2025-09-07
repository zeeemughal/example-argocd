# Media Server Helm Chart

Enterprise-grade Helm chart for deploying a complete media server stack with microservices architecture.

## Applications

- **Jellyfin** - Media server and streaming platform
- **Jackett** - Torrent indexer proxy
- **Bazarr** - Subtitle management
- **qBittorrent** - Torrent client
- **Radarr** - Movie collection manager

## Architecture

- **Microservices Design**: Separate deployment per service
- **Shared Storage**: Single PVC with subPaths per service
- **Individual Ingresses**: Separate ingress per service with custom annotations
- **Independent Scaling**: Scale each service individually
- **Fault Isolation**: Service failures don't affect others

## Quick Start

```bash
# Install with default values
helm install media-server ./media-server -n media-server --create-namespace

# Install with custom values
helm install media-server ./media-server -n media-server --create-namespace -f custom-values.yaml
```

## Configuration

### Global Settings

```yaml
global:
  timezone: "Etc/UTC"
  puid: 1000
  pgid: 1000
  umask: "002"
```

### Storage Configuration

```yaml
storage:
  type: "pvc"  # pvc, hostPath, emptyDir
  pvc:
    create: true
    name: "media-server-pvc"
    size: "100Gi"
    storageClass: "longhorn"
    accessModes: ["ReadWriteOnce"]
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  tls:
    enabled: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
  annotations:
    external-dns.alpha.kubernetes.io/enabled: "true"
```

### Per-Service Configuration

Each service can be configured independently:

```yaml
jellyfin:
  enabled: true
  image:
    repository: "linuxserver/jellyfin"
    tag: "latest"
  initContainer:
    enabled: true  # Creates media folders automatically
  resources:
    enabled: false  # Enable for production
  ingress:
    enabled: true
    hostname: "jellyfin.example.com"
    annotations: {}  # Service-specific annotations
```

## Features

### ✅ Production Ready
- Microservices architecture
- Independent scaling and updates
- Fault isolation
- Professional Helm chart structure

### ✅ Storage Management
- Shared PVC with subPaths
- Automatic media folder creation
- Flexible storage backends

### ✅ Networking
- Individual ingresses per service
- TLS certificate management
- External DNS integration
- Performance optimizations

### ✅ Customization
- Per-service resource limits
- Custom environment variables
- Flexible mount paths
- Service-specific annotations

## Default Credentials

- **qBittorrent**: Check pod logs for temporary password
  ```bash
  kubectl logs <qbittorrent-pod> -n media-server | grep password
  ```

## Monitoring

Check deployment status:
```bash
kubectl get pods -n media-server
kubectl get ingress -n media-server
kubectl get pvc -n media-server
```

## Troubleshooting

### Common Issues

1. **Storage Issues**: Ensure storage class exists and has sufficient space
2. **Ingress Issues**: Verify ingress controller and DNS configuration
3. **Permission Issues**: Check PUID/PGID settings match your storage

### Logs

```bash
# Check specific service logs
kubectl logs deployment/media-server-jellyfin -n media-server

# Check init container logs
kubectl logs <pod-name> -n media-server -c init-media-folders
```

## Values Reference

See `values.yaml` for complete configuration options including:
- Image repositories and tags
- Resource limits and requests
- Volume mount configurations
- Service and ingress settings
- Environment variables

## License

This chart is provided as-is for educational and personal use.
