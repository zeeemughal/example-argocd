# Longhorn Storage Chart

This chart deploys Longhorn distributed block storage for Kubernetes.

## Configuration

### Single Node Cluster Settings
- `defaultReplicaCount: 1` - Single replica for single node (set to 3 for multi-node)
- `replicaSoftAntiAffinity: false` - Disabled for single node (enable for multi-node)
- `replicaZoneSoftAntiAffinity: false` - Disabled for single node (enable for multi-zone)
- `replicaDiskSoftAntiAffinity: false` - Disabled for single node (enable for multi-node)
- `longhornUI.replicas: 1` - Single UI replica (set to 2 for multi-node)

### Authentication
Basic HTTP authentication is enabled for the Longhorn UI via nginx ingress.

**Required Setup:**
1. Create basic auth secret:
   ```bash
   kubectl create secret generic basic-auth --from-literal=auth=$(htpasswd -nb admin yourpassword) -n longhorn-system
   ```

2. Default credentials: `admin/admin`

### Storage Configuration
- Default data path: `/var/lib/longhorn/`
- Storage over-provisioning: 200%
- Storage reserved percentage: 30%

### Node Setup
**Required for storage to appear:**
1. Label nodes for default disk creation:
   ```bash
   kubectl label node <node-name> node.longhorn.io/create-default-disk=true
   ```

2. The chart automatically creates default disks on labeled nodes with:
   - `createDefaultDiskLabeledNodes: true`
   - `createDefaultDiskOnLabeledNodes: true`

### Access
- UI URL: https://longhorn.dev.786999.xyz
- Credentials: admin/admin (after creating basic-auth secret)

### Prerequisites
- nginx-ingress-controller
- cert-manager (for TLS)
- external-dns (for DNS management)
