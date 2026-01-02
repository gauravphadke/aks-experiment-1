# Kubernetes Deployment Guide

Complete guide for deploying Flask Video Streaming application to Kubernetes with LoadBalancer support.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [Deployment Options](#deployment-options)
- [Configuration](#configuration)
- [Scaling](#scaling)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cloud Provider Specific](#cloud-provider-specific)

---

## Prerequisites

### Required
- **Kubernetes cluster** (v1.24+)
  - Managed: AKS, EKS, GKE
  - Self-hosted: kubeadm, k3s, minikube
- **kubectl** installed and configured
- **Docker** (for building images)
- **Container Registry** (ACR, ECR, GCR, Docker Hub)

### Optional
- **Helm** (for advanced deployments)
- **Kustomize** (for configuration management)
- **kubectl metrics-server** (for HPA)

### Install kubectl

**Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**macOS:**
```bash
brew install kubectl
```

**Windows:**
```powershell
choco install kubernetes-cli
```

Verify:
```bash
kubectl version --client
```

---

## Quick Start

### 1. Build Docker Image

```bash
# From project root
docker build -t flask-video-app:latest .
```

### 2. Push to Registry (Optional but Recommended)

**Azure Container Registry (ACR):**
```bash
# Login
az acr login --name myregistry

# Tag and push
docker tag flask-video-app:latest myregistry.azurecr.io/flask-video-app:latest
docker push myregistry.azurecr.io/flask-video-app:latest
```

**Docker Hub:**
```bash
docker login
docker tag flask-video-app:latest username/flask-video-app:latest
docker push username/flask-video-app:latest
```

### 3. Update Image in Manifests

Edit `k8s/deployment.yaml` (or `k8s/all-in-one.yaml`):
```yaml
containers:
- name: flask-video-streaming
  image: myregistry.azurecr.io/flask-video-app:latest  # Your registry
```

### 4. Deploy to Kubernetes

**Option A: Using the deployment script (easiest)**
```bash
chmod +x k8s-deploy.sh
./k8s-deploy.sh full
```

**Option B: Using kubectl**
```bash
# Deploy all resources at once
kubectl apply -f k8s/all-in-one.yaml

# Or deploy individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
```

**Option C: Using Kustomize**
```bash
kubectl apply -k k8s/
```

### 5. Get LoadBalancer IP

```bash
kubectl get service flask-video-streaming -n flask-video-streaming

# Wait for EXTERNAL-IP
kubectl get service flask-video-streaming -n flask-video-streaming --watch
```

### 6. Access Application

Once you have the external IP:
```
http://<EXTERNAL-IP>
```

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────┐
│                     LoadBalancer                        │
│                  (External Traffic)                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                Kubernetes Service                        │
│          (Session Affinity: ClientIP)                   │
└───────┬──────────────┬──────────────┬───────────────────┘
        │              │              │
   ┌────▼────┐    ┌───▼─────┐   ┌───▼─────┐
   │  Pod 1  │    │  Pod 2  │   │  Pod 3  │
   │         │    │         │   │         │
   │ Flask + │    │ Flask + │   │ Flask + │
   │ Gunicorn│    │ Gunicorn│   │ Gunicorn│
   │         │    │         │   │         │
   │ tmpfs   │    │ tmpfs   │   │ tmpfs   │
   │  2GB    │    │  2GB    │   │  2GB    │
   └─────────┘    └─────────┘   └─────────┘
```

### Resources Created

1. **Namespace**: `flask-video-streaming`
2. **ConfigMap**: Application configuration
3. **Deployment**: 3 replicas (configurable)
4. **Service**: LoadBalancer type, port 80 → 5000
5. **HorizontalPodAutoscaler**: Auto-scaling 3-10 pods
6. **PodDisruptionBudget**: Ensures 2 pods always available
7. **ResourceQuota**: Limits namespace resources

### Storage Strategy

- **emptyDir with Memory medium**: Videos stored in RAM (tmpfs)
- **Size**: 2GB per pod (configurable)
- **Behavior**: Cleared when pod restarts
- **Performance**: Ultra-fast I/O from memory

---

## Deployment Options

### Option 1: All-in-One Deployment (Recommended)

Single file with all resources:

```bash
kubectl apply -f k8s/all-in-one.yaml
```

**Pros:**
- Simple, one command
- Easy to version control
- Good for CI/CD

**Cons:**
- Harder to customize individual resources

### Option 2: Individual Files

Deploy resources separately:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
```

**Pros:**
- Granular control
- Update individual resources

**Cons:**
- More commands
- Must maintain order

### Option 3: Kustomize

Use Kustomize for configuration management:

```bash
kubectl apply -k k8s/
```

**Pros:**
- Environment-specific configs
- DRY principle
- Advanced overlays

**Cons:**
- Learning curve

### Option 4: Helm Chart

For advanced deployments, consider creating a Helm chart.

---

## Configuration

### Environment Variables

Edit `k8s/configmap.yaml`:

```yaml
data:
  FLASK_ENV: "production"
  PYTHONUNBUFFERED: "1"
  GUNICORN_WORKERS: "4"       # Number of worker processes
  GUNICORN_TIMEOUT: "300"     # Request timeout (seconds)
  MAX_CONTENT_LENGTH: "524288000"  # Max upload size (500MB)
```

### Resource Limits

Edit `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"   # Minimum memory
    cpu: "250m"       # Minimum CPU (0.25 cores)
  limits:
    memory: "3Gi"     # Maximum memory
    cpu: "1000m"      # Maximum CPU (1 core)
```

### tmpfs Size

Adjust memory storage for videos:

```yaml
volumes:
- name: video-storage
  emptyDir:
    medium: Memory
    sizeLimit: 2Gi    # Change to 4Gi, 8Gi, etc.
```

### Replica Count

Change number of pods:

```yaml
spec:
  replicas: 3    # Change to desired count
```

### LoadBalancer Annotations

**Azure (AKS):**
```yaml
annotations:
  # External load balancer (default)
  service.beta.kubernetes.io/azure-load-balancer-internal: "false"
  
  # Internal load balancer
  # service.beta.kubernetes.io/azure-load-balancer-internal: "true"
  # service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "subnet-name"
```

**AWS (EKS):**
```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
  service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

**GCP (GKE):**
```yaml
annotations:
  cloud.google.com/load-balancer-type: "External"
```

---

## Scaling

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment flask-video-streaming -n flask-video-streaming --replicas=5

# Verify
kubectl get pods -n flask-video-streaming
```

### Auto-Scaling (HPA)

Already configured via `k8s/hpa.yaml`:

```yaml
minReplicas: 3
maxReplicas: 10
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70    # Scale up at 70% CPU
- type: Resource
  resource:
    name: memory
    target:
      type: Utilization
      averageUtilization: 80    # Scale up at 80% memory
```

**View HPA status:**
```bash
kubectl get hpa -n flask-video-streaming
kubectl describe hpa flask-video-streaming-hpa -n flask-video-streaming
```

**Modify HPA:**
```bash
kubectl edit hpa flask-video-streaming-hpa -n flask-video-streaming
```

### Prerequisites for HPA

Ensure metrics-server is installed:

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# Install if needed
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## Monitoring

### Check Pod Status

```bash
# List pods
kubectl get pods -n flask-video-streaming

# Detailed info
kubectl describe pod <POD_NAME> -n flask-video-streaming

# Watch pods
kubectl get pods -n flask-video-streaming --watch
```

### View Logs

```bash
# Logs from all pods
kubectl logs -l app=flask-video-streaming -n flask-video-streaming --tail=100

# Logs from specific pod
kubectl logs <POD_NAME> -n flask-video-streaming -f

# Previous pod logs (if crashed)
kubectl logs <POD_NAME> -n flask-video-streaming --previous
```

### Check Service

```bash
# Service details
kubectl get service flask-video-streaming -n flask-video-streaming

# Detailed info
kubectl describe service flask-video-streaming -n flask-video-streaming

# Endpoints (pod IPs)
kubectl get endpoints flask-video-streaming -n flask-video-streaming
```

### Resource Usage

```bash
# Pod resource usage
kubectl top pods -n flask-video-streaming

# Node resource usage
kubectl top nodes
```

### Check tmpfs Usage

```bash
# SSH into pod
kubectl exec -it <POD_NAME> -n flask-video-streaming -- bash

# Check tmpfs
df -h /app/static/videos

# List cached videos
ls -lh /app/static/videos
```

### Events

```bash
# Namespace events
kubectl get events -n flask-video-streaming --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n flask-video-streaming --watch
```

---

## Troubleshooting

### Pods Not Starting

**Check pod status:**
```bash
kubectl get pods -n flask-video-streaming
kubectl describe pod <POD_NAME> -n flask-video-streaming
```

**Common issues:**
1. **ImagePullBackOff**: Image not found in registry
   ```bash
   # Check image name in deployment
   kubectl get deployment flask-video-streaming -n flask-video-streaming -o yaml | grep image:
   ```

2. **CrashLoopBackOff**: Application crashing
   ```bash
   # Check logs
   kubectl logs <POD_NAME> -n flask-video-streaming --previous
   ```

3. **Pending**: Insufficient resources
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   ```

### LoadBalancer Pending

If external IP stays `<pending>`:

**Check cloud provider support:**
```bash
kubectl get service flask-video-streaming -n flask-video-streaming
```

**Troubleshooting steps:**

1. **Check cloud provider**: Ensure LoadBalancer is supported
2. **Check quotas**: Verify you haven't exceeded IP/LB limits
3. **Check service events**:
   ```bash
   kubectl describe service flask-video-streaming -n flask-video-streaming
   ```

4. **Alternative: Use NodePort**:
   ```yaml
   spec:
     type: NodePort  # Instead of LoadBalancer
   ```

### Video Downloads Failing

**Check tmpfs space:**
```bash
kubectl exec -it <POD_NAME> -n flask-video-streaming -- df -h /app/static/videos
```

**Increase tmpfs size** in `deployment.yaml`:
```yaml
volumes:
- name: video-storage
  emptyDir:
    medium: Memory
    sizeLimit: 4Gi  # Increase from 2Gi
```

**Check memory limits:**
```yaml
resources:
  limits:
    memory: "5Gi"  # Must be > tmpfs size + app memory
```

### HPA Not Scaling

**Check metrics-server:**
```bash
kubectl get deployment metrics-server -n kube-system
kubectl top pods -n flask-video-streaming
```

**Check HPA status:**
```bash
kubectl describe hpa flask-video-streaming-hpa -n flask-video-streaming
```

**Generate load for testing:**
```bash
# Install hey (HTTP load generator)
# Then generate load
hey -z 60s -c 50 http://<EXTERNAL-IP>/
```

### High Memory Usage

**Check pod memory:**
```bash
kubectl top pods -n flask-video-streaming
```

**Solutions:**
1. Reduce tmpfs size
2. Increase memory limits
3. Scale horizontally (more pods)

---

## Cloud Provider Specific

### Azure Kubernetes Service (AKS)

**Create AKS cluster:**
```bash
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys
```

**Get credentials:**
```bash
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

**Use Azure Container Registry:**
```bash
# Create ACR
az acr create --resource-group myResourceGroup --name myregistry --sku Basic

# Attach ACR to AKS
az aks update --name myAKSCluster --resource-group myResourceGroup --attach-acr myregistry

# Build and push
az acr build --registry myregistry --image flask-video-app:latest .
```

**Update deployment:**
```yaml
image: myregistry.azurecr.io/flask-video-app:latest
```

**Internal LoadBalancer:**
```yaml
annotations:
  service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

### Amazon EKS

**Create EKS cluster:**
```bash
eksctl create cluster \
  --name my-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3
```

**Get credentials:**
```bash
aws eks update-kubeconfig --region us-west-2 --name my-cluster
```

**Use ECR:**
```bash
# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-west-2.amazonaws.com

# Create repository
aws ecr create-repository --repository-name flask-video-app --region us-west-2

# Tag and push
docker tag flask-video-app:latest <account>.dkr.ecr.us-west-2.amazonaws.com/flask-video-app:latest
docker push <account>.dkr.ecr.us-west-2.amazonaws.com/flask-video-app:latest
```

**Network LoadBalancer:**
```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
```

### Google Kubernetes Engine (GKE)

**Create GKE cluster:**
```bash
gcloud container clusters create my-cluster \
  --num-nodes=3 \
  --machine-type=n1-standard-2 \
  --zone=us-central1-a
```

**Get credentials:**
```bash
gcloud container clusters get-credentials my-cluster --zone=us-central1-a
```

**Use GCR:**
```bash
# Tag and push
docker tag flask-video-app:latest gcr.io/PROJECT_ID/flask-video-app:latest
docker push gcr.io/PROJECT_ID/flask-video-app:latest
```

---

## Production Best Practices

### 1. Use Container Registry

Always push images to a registry:
- Azure: Azure Container Registry (ACR)
- AWS: Elastic Container Registry (ECR)
- GCP: Google Container Registry (GCR)
- Generic: Docker Hub, Quay.io

### 2. Image Tagging

Use semantic versioning:
```bash
docker build -t flask-video-app:1.0.0 .
docker build -t flask-video-app:latest .
```

### 3. Resource Quotas

Already configured in `resourcequota.yaml` to prevent resource exhaustion.

### 4. Pod Disruption Budget

Configured in `pdb.yaml` to ensure availability during maintenance.

### 5. Health Checks

Already configured:
- **Liveness probe**: Restart pod if unhealthy
- **Readiness probe**: Remove from load balancer if not ready

### 6. Secrets Management

For sensitive data, use Kubernetes Secrets:
```bash
kubectl create secret generic api-keys \
  --from-literal=key=value \
  -n flask-video-streaming
```

### 7. Network Policies

Add network policies for security:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: flask-video-streaming-netpol
spec:
  podSelector:
    matchLabels:
      app: flask-video-streaming
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5000
```

### 8. Monitoring & Logging

Consider adding:
- **Prometheus** for metrics
- **Grafana** for dashboards
- **ELK/EFK** stack for logs
- **Jaeger** for tracing

---

## Cleanup

### Delete All Resources

```bash
# Delete namespace (removes everything)
kubectl delete namespace flask-video-streaming

# Or use deployment script
./k8s-deploy.sh delete
```

### Delete Specific Resources

```bash
kubectl delete deployment flask-video-streaming -n flask-video-streaming
kubectl delete service flask-video-streaming -n flask-video-streaming
kubectl delete hpa flask-video-streaming-hpa -n flask-video-streaming
```

---

## Quick Reference

### Essential Commands

```bash
# Deploy
kubectl apply -f k8s/all-in-one.yaml

# Get LoadBalancer IP
kubectl get svc flask-video-streaming -n flask-video-streaming

# Check status
kubectl get all -n flask-video-streaming

# View logs
kubectl logs -l app=flask-video-streaming -n flask-video-streaming -f

# Scale
kubectl scale deployment flask-video-streaming --replicas=5 -n flask-video-streaming

# Delete
kubectl delete namespace flask-video-streaming
```

---

## Next Steps

1. ✅ Deploy to Kubernetes
2. 📊 Set up monitoring (Prometheus/Grafana)
3. 🔒 Configure TLS/HTTPS (cert-manager)
4. 🌐 Set up Ingress for advanced routing
5. 🚀 Implement CI/CD pipeline
6. 📈 Performance testing and tuning

---

## Support

- **Kubernetes Docs**: https://kubernetes.io/docs/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **This Project**: See README.md and other docs
