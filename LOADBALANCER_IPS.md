# LoadBalancer and Public IP Management in AKS

## How LoadBalancer IPs Work in AKS

### Automatic IP Management

When you create a Kubernetes Service with `type: LoadBalancer` in AKS, the following happens automatically:

1. **Azure Cloud Controller Manager** detects the LoadBalancer service
2. **Automatically creates** an Azure Load Balancer in the **node resource group**
3. **Automatically creates** a public IP and assigns it to the load balancer
4. **Updates** the Kubernetes service with the external IP

### Node Resource Group

AKS creates a separate resource group for cluster infrastructure:
- **Name format**: `MC_<resource-group>_<cluster-name>_<location>`
- **Contains**: Load balancers, public IPs, VM scale sets, disks, NSGs
- **Managed by**: AKS (don't modify manually)

### Example Flow

```
1. You create Kubernetes Service:
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: flask-video-streaming
   spec:
     type: LoadBalancer  # <-- This triggers automatic IP creation
     ports:
     - port: 80
   ---

2. AKS automatically creates in node resource group:
   - Azure Load Balancer: kubernetes-<service-name>
   - Public IP: kubernetes-<random-id>
   - Backend pool linked to pods

3. IP is assigned to service:
   kubectl get svc flask-video-streaming
   NAME                    EXTERNAL-IP      PORT(S)
   flask-video-streaming   20.185.123.45    80:30123/TCP
```

## Why Not Pre-Create the Public IP?

### Reasons

1. **AKS Manages It**: Cloud controller automatically handles IP lifecycle
2. **Dynamic Assignment**: Each LoadBalancer service gets its own IP
3. **Cleanup**: IPs are removed when services are deleted
4. **Simpler**: No manual IP management needed

### If You Want a Static IP (Advanced)

If you need a **specific static IP** for your LoadBalancer:

#### Option 1: Pre-create IP and Use Annotation

**Terraform:**
```hcl
# Create public IP in node resource group
resource "azurerm_public_ip" "loadbalancer" {
  name                = "${var.cluster_name}-lb-static-ip"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

output "static_ip_address" {
  value = azurerm_public_ip.loadbalancer.ip_address
}
```

**Kubernetes Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-video-streaming
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: MC_flask-video-streaming-rg_flask-video-aks_eastus
spec:
  type: LoadBalancer
  loadBalancerIP: 20.185.123.45  # Your static IP
  ports:
  - port: 80
    targetPort: 5000
```

#### Option 2: Use Existing IP from Different Resource Group

**Terraform:**
```hcl
# Create public IP in your own resource group
resource "azurerm_public_ip" "custom" {
  name                = "${var.cluster_name}-custom-ip"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name  # Your RG, not node RG
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Grant AKS permission to use this IP
resource "azurerm_role_assignment" "ip_contributor" {
  scope                = azurerm_public_ip.custom.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

**Kubernetes Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-video-streaming
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: flask-video-streaming-rg
spec:
  type: LoadBalancer
  loadBalancerIP: 20.185.123.45
  ports:
  - port: 80
```

## Internal Load Balancer

For **internal** (private) load balancers, use annotations:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-video-streaming
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    # Optional: specific subnet
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "backend-subnet"
spec:
  type: LoadBalancer
  ports:
  - port: 80
```

This creates a load balancer with a **private IP** from your VNet.

## Multiple LoadBalancer Services

Each LoadBalancer service gets its **own public IP**:

```
Service 1: flask-video-streaming    -> IP: 20.185.123.45
Service 2: flask-admin-panel         -> IP: 20.185.123.46
Service 3: flask-api-backend         -> IP: 20.185.123.47
```

All IPs are created automatically in the node resource group.

## Finding Your LoadBalancer IP

### Method 1: kubectl
```bash
kubectl get service flask-video-streaming -n flask-video-streaming

# Wait for EXTERNAL-IP to appear
kubectl get service flask-video-streaming -n flask-video-streaming --watch
```

### Method 2: Azure CLI
```bash
# List all public IPs in node resource group
az network public-ip list \
  --resource-group MC_flask-video-streaming-rg_flask-video-aks_eastus \
  --output table

# Get specific IP by tag
az network public-ip list \
  --resource-group MC_flask-video-streaming-rg_flask-video-aks_eastus \
  --query "[?tags.service=='flask-video-streaming'].ipAddress" -o tsv
```

### Method 3: Azure Portal
1. Navigate to the **node resource group** (MC_...)
2. Look for **Public IP addresses**
3. Find IP with name starting with `kubernetes-`

## Cost Considerations

### Public IP Pricing
- **Static Public IP**: ~$3.65/month
- **Dynamic Public IP**: ~$2.92/month
- **Data transfer**: Billed separately

### Optimization
- **Use Ingress** instead of multiple LoadBalancers
  - 1 public IP for multiple services
  - Lower cost (1 IP vs many)
  - Better routing

**Example with Ingress:**
```yaml
# Only 1 LoadBalancer (Ingress Controller)
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
spec:
  type: LoadBalancer  # Only LoadBalancer service
  ports:
  - port: 80

---
# Multiple apps behind 1 IP
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-apps
spec:
  rules:
  - host: video.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: flask-video-streaming
  - host: admin.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: flask-admin-panel
```

## Best Practices

### 1. Use Automatic IPs (Default)
✅ **Recommended for most use cases**
- Let AKS manage IP lifecycle
- Automatic cleanup
- No manual intervention needed

### 2. Use Static IP When:
- Need **consistent IP** for DNS records
- Firewall rules require **specific IP**
- Compliance requires **IP whitelisting**

### 3. Use Ingress When:
- Multiple services need **external access**
- Want **path-based routing** (e.g., /api, /admin)
- Need **TLS termination**
- Want to **reduce costs** (1 IP vs many)

### 4. Use Internal LB When:
- Service only accessed **within VNet**
- **Private** application (not internet-facing)
- **Backend** services (databases, APIs)

## Common Issues

### Issue: IP Stays `<pending>`

**Causes:**
- Insufficient quota
- Network policy blocking
- Cloud controller errors

**Debug:**
```bash
# Check service events
kubectl describe service flask-video-streaming -n flask-video-streaming

# Check cloud controller logs
kubectl logs -n kube-system -l component=cloud-controller-manager
```

### Issue: Can't Access Application

**Causes:**
- NSG blocking traffic
- Wrong port mapping
- Application not ready

**Debug:**
```bash
# Check endpoints
kubectl get endpoints flask-video-streaming -n flask-video-streaming

# Check pods
kubectl get pods -n flask-video-streaming

# Test from within cluster
kubectl run test --rm -it --image=busybox -- wget -O- http://flask-video-streaming.flask-video-streaming.svc.cluster.local
```

### Issue: IP Changes After Restart

**Cause:** Using dynamic IP (default behavior)

**Solution:** Use static IP with annotation (see above)

## Summary

| Scenario | Solution |
|----------|----------|
| Simple app, don't care about IP | Use default (automatic IP) ✅ |
| Need same IP after redeploy | Use static IP + annotation |
| Multiple services | Use Ingress Controller |
| Private/internal app | Use internal LoadBalancer |
| Want to manage IP lifecycle | Pre-create IP in Terraform |

## Current Implementation

In this project, we use the **default automatic IP** approach:
- ✅ Kubernetes Service with `type: LoadBalancer`
- ✅ AKS automatically creates and manages public IP
- ✅ IP appears in `EXTERNAL-IP` field after ~1-2 minutes
- ✅ IP deleted automatically when service is deleted

**No Terraform public IP resource needed!**

## Example: Getting the IP After Deployment

```bash
# Deploy application
kubectl apply -f k8s/all-in-one.yaml

# Wait for IP (automatic)
kubectl get service flask-video-streaming -n flask-video-streaming --watch

# Access application
EXTERNAL_IP=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application: http://${EXTERNAL_IP}"
```

That's it! No manual IP management required. 🎉
