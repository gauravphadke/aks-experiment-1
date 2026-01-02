# Terraform AKS Deployment Guide

Complete guide for deploying Azure Kubernetes Service (AKS) cluster using Terraform for the Flask Video Streaming application.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment Steps](#deployment-steps)
- [Post-Deployment](#post-deployment)
- [Infrastructure Details](#infrastructure-details)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Overview

This Terraform configuration creates a production-ready AKS cluster with:

- ✅ **Minimum 3 nodes** (validated in configuration)
- ✅ **System node pool** (3 nodes) for Kubernetes system components
- ✅ **User node pool** (3 nodes) for application workloads
- ✅ **Auto-scaling** enabled (3-10 nodes)
- ✅ **Azure Container Registry** (ACR) for storing Docker images
- ✅ **Virtual Network** with dedicated subnet
- ✅ **Azure Monitor** integration with Log Analytics
- ✅ **Azure AD** authentication (optional)
- ✅ **LoadBalancer** support with public IP

### Infrastructure Created

```
Azure Subscription
├── Resource Group
│   ├── Virtual Network (VNet)
│   │   └── Subnet (for AKS nodes)
│   ├── AKS Cluster
│   │   ├── System Node Pool (3-6 nodes)
│   │   └── User Node Pool (3-10 nodes)
│   ├── Azure Container Registry (ACR)
│   ├── Log Analytics Workspace
│   ├── User Assigned Identity
│   └── Public IP (for LoadBalancer)
└── Node Resource Group (auto-created)
    └── Infrastructure resources
```

---

## Prerequisites

### Required Tools

1. **Terraform** (>= 1.0)
   ```bash
   # Install Terraform
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Windows
   choco install terraform
   
   # Verify
   terraform version
   ```

2. **Azure CLI** (>= 2.50.0)
   ```bash
   # Install Azure CLI
   # macOS
   brew install azure-cli
   
   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Windows
   choco install azure-cli
   
   # Verify
   az --version
   ```

3. **kubectl**
   ```bash
   # Install kubectl
   az aks install-cli
   
   # Or use package manager
   brew install kubectl    # macOS
   sudo apt-get install kubectl  # Linux
   choco install kubernetes-cli   # Windows
   
   # Verify
   kubectl version --client
   ```

### Azure Requirements

1. **Azure Subscription**
   - Active Azure subscription
   - Sufficient quota for resources

2. **Permissions**
   - Contributor or Owner role on subscription
   - Permissions to create service principals (if using Azure AD)

3. **Login to Azure**
   ```bash
   az login
   
   # Set subscription
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   
   # Verify
   az account show
   ```

---

## Quick Start

### 1. Clone/Navigate to Terraform Directory

```bash
cd flask-video-app/terraform
```

### 2. Create Configuration File

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

### 6. Get Cluster Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)
```

### 7. Verify Cluster

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Configuration

### Minimum Configuration (terraform.tfvars)

```hcl
# Basic settings
resource_group_name = "flask-video-streaming-rg"
location            = "East US"
cluster_name        = "flask-video-aks"

# Node pools (minimum 3 nodes each)
system_node_count = 3
user_node_count   = 3

# Enable essential features
enable_auto_scaling  = true
enable_log_analytics = true
create_acr           = true
```

### Production Configuration

```hcl
# Basic Configuration
resource_group_name = "flask-video-streaming-prod-rg"
location            = "East US"
cluster_name        = "flask-video-aks-prod"
environment         = "production"
kubernetes_version  = "1.28.3"

# Network
vnet_address_space    = "10.0.0.0/16"
subnet_address_prefix = "10.0.1.0/24"
network_plugin        = "azure"
network_policy        = "azure"

# System Node Pool (3-6 nodes)
system_node_count     = 3
system_node_vm_size   = "Standard_D2s_v3"
system_node_min_count = 3
system_node_max_count = 6

# User Node Pool (3-10 nodes)
user_node_count     = 3
user_node_vm_size   = "Standard_D4s_v3"
user_node_min_count = 3
user_node_max_count = 10

# Features
enable_auto_scaling         = true
enable_azure_ad_integration = true
enable_azure_rbac           = true
enable_log_analytics        = true
create_acr                  = true

# Tags
tags = {
  Application = "Flask-Video-Streaming"
  Environment = "Production"
  ManagedBy   = "Terraform"
}
```

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | flask-video-streaming-rg | Resource group name |
| `location` | East US | Azure region |
| `cluster_name` | flask-video-aks | AKS cluster name |
| `system_node_count` | 3 | System node count (min 3) |
| `user_node_count` | 3 | User node count |
| `enable_auto_scaling` | true | Enable auto-scaling |
| `create_acr` | true | Create ACR |
| `enable_log_analytics` | true | Enable monitoring |

See `variables.tf` for complete list.

---

## Deployment Steps

### Step 1: Prepare Configuration

```bash
cd terraform

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
resource_group_name = "flask-video-streaming-rg"
location            = "East US"
cluster_name        = "flask-video-aks"
system_node_count   = 3
user_node_count     = 3
EOF
```

### Step 2: Initialize Terraform

```bash
# Download providers
terraform init

# Optional: Validate configuration
terraform validate
```

### Step 3: Plan Deployment

```bash
# Review what will be created
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan
```

### Step 4: Apply Configuration

```bash
# Apply changes
terraform apply

# Or apply saved plan
terraform apply tfplan

# Type 'yes' when prompted
```

**Expected duration:** 10-15 minutes

### Step 5: Verify Outputs

```bash
# View all outputs
terraform output

# Specific outputs
terraform output cluster_name
terraform output acr_login_server
terraform output deployment_summary
```

### Step 6: Configure kubectl

```bash
# Get credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)

# Verify connection
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

---

## Post-Deployment

### 1. Verify Cluster

```bash
# Check nodes (should see 6+ nodes)
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE
# aks-system-xxxxx-vmssxxxxx          Ready    agent   5m
# aks-system-xxxxx-vmssxxxxx          Ready    agent   5m
# aks-system-xxxxx-vmssxxxxx          Ready    agent   5m
# aks-user-xxxxx-vmssxxxxx            Ready    agent   5m
# aks-user-xxxxx-vmssxxxxx            Ready    agent   5m
# aks-user-xxxxx-vmssxxxxx            Ready    agent   5m

# Check node pools
kubectl get nodes --show-labels | grep agentpool
```

### 2. Configure ACR Integration

```bash
# Get ACR name
ACR_NAME=$(terraform output -raw acr_name)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push Flask app image
docker build -t flask-video-app:latest ..
docker tag flask-video-app:latest ${ACR_NAME}.azurecr.io/flask-video-app:latest
docker push ${ACR_NAME}.azurecr.io/flask-video-app:latest

# Verify image
az acr repository list --name $ACR_NAME
```

### 3. Update Kubernetes Manifests

Update image in `k8s/deployment.yaml`:

```yaml
containers:
- name: flask-video-streaming
  image: <ACR_NAME>.azurecr.io/flask-video-app:latest
```

Replace `<ACR_NAME>` with your ACR name from `terraform output acr_name`.

### 4. Deploy Application

```bash
# Deploy to Kubernetes
kubectl apply -f ../k8s/all-in-one.yaml

# Or use deployment script
cd ..
./k8s-deploy.sh deploy
```

### 5. Get LoadBalancer IP

```bash
# Wait for external IP
kubectl get service flask-video-streaming -n flask-video-streaming --watch

# Once assigned
EXTERNAL_IP=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://${EXTERNAL_IP}"
```

### 6. Verify Monitoring

```bash
# Check Log Analytics
az monitor log-analytics workspace show \
  --resource-group $(terraform output -raw resource_group_name) \
  --workspace-name $(terraform output -raw cluster_name)-law

# View in Azure Portal
# Navigate to: AKS Cluster -> Monitoring -> Insights
```

---

## Infrastructure Details

### Node Pools

**System Node Pool (system)**
- Purpose: Kubernetes system components
- Count: 3 nodes (minimum)
- VM Size: Standard_D2s_v3
- Auto-scaling: 3-6 nodes
- Mode: System
- Taints: None

**User Node Pool (user)**
- Purpose: Application workloads
- Count: 3 nodes (minimum)
- VM Size: Standard_D4s_v3
- Auto-scaling: 3-10 nodes
- Mode: User
- Labels: workload=application

### Network Configuration

- **VNet**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24
- **Service CIDR**: 10.1.0.0/16
- **DNS Service IP**: 10.1.0.10
- **Network Plugin**: Azure CNI
- **Network Policy**: Azure

### VM Sizes Reference

| VM Size | vCPUs | RAM | Temp Storage | Cost/Month* |
|---------|-------|-----|--------------|-------------|
| Standard_D2s_v3 | 2 | 8 GB | 16 GB | ~$73 |
| Standard_D4s_v3 | 4 | 16 GB | 32 GB | ~$146 |
| Standard_D8s_v3 | 8 | 32 GB | 64 GB | ~$292 |

*Approximate US East pricing

### Resource Requirements

**Minimum:**
- 6 nodes × 2 vCPU = 12 vCPU
- 6 nodes × 8 GB RAM = 48 GB RAM

**Maximum (with auto-scaling):**
- 16 nodes × 4 vCPU = 64 vCPU
- 16 nodes × 16 GB RAM = 256 GB RAM

---

## Cost Optimization

### Estimated Monthly Costs

**Minimum Configuration (6 nodes):**
- 3 × Standard_D2s_v3: ~$219/month
- 3 × Standard_D4s_v3: ~$438/month
- ACR Standard: ~$20/month
- Log Analytics: ~$30/month (approx.)
- LoadBalancer: ~$20/month
- **Total: ~$727/month**

### Cost Reduction Strategies

1. **Use Smaller VM Sizes**
   ```hcl
   system_node_vm_size = "Standard_B2s"   # $30/month
   user_node_vm_size   = "Standard_B4ms"  # $120/month
   ```

2. **Reduce Node Count (Dev/Test)**
   ```hcl
   system_node_count = 3  # Keep minimum
   user_node_count   = 2  # Reduce for dev
   ```

3. **Use Spot Instances**
   ```hcl
   # Add to node pool configuration
   priority        = "Spot"
   eviction_policy = "Delete"
   spot_max_price  = -1  # Pay up to regular price
   ```

4. **Scale Down After Hours**
   ```bash
   # Scale to minimum
   kubectl scale deployment flask-video-streaming --replicas=1 -n flask-video-streaming
   az aks nodepool scale --node-count 3 --name user \
     --cluster-name <cluster-name> --resource-group <rg-name>
   ```

5. **Use Azure Dev/Test Pricing**
   - If you have MSDN subscription
   - Significant discounts on VM prices

---

## Troubleshooting

### Issue: Terraform Init Fails

**Error:** `Failed to install provider`

**Solution:**
```bash
# Clear cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

### Issue: Insufficient Quota

**Error:** `The subscription does not have enough quota`

**Solution:**
```bash
# Check quota
az vm list-usage --location "East US" --query "[?name.value=='standardDSv3Family']"

# Request increase
az support tickets create \
  --title "Increase VM quota" \
  --ticket-name "quota-increase"
```

### Issue: Azure AD Group Not Found

**Error:** `admin_group_object_ids is invalid`

**Solution:**
```bash
# Get your Azure AD group ID
az ad group show --group "AKS Admins" --query id -o tsv

# Add to terraform.tfvars
admin_group_object_ids = ["<GROUP_ID>"]
```

### Issue: ACR Pull Failed

**Error:** `Failed to pull image from ACR`

**Solution:**
```bash
# Verify ACR integration
az aks check-acr \
  --resource-group <rg-name> \
  --name <cluster-name> \
  --acr <acr-name>

# Re-attach if needed
az aks update \
  --resource-group <rg-name> \
  --name <cluster-name> \
  --attach-acr <acr-name>
```

### Issue: Nodes Not Ready

**Error:** Nodes stuck in `NotReady` state

**Solution:**
```bash
# Check node events
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# Restart kubelet (if needed)
kubectl delete pod <kube-proxy-pod> -n kube-system
```

### Issue: Terraform State Lock

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>

# Or wait for timeout (usually 20 minutes)
```

---

## Cleanup

### Destroy Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Note:** This will delete:
- AKS cluster and all deployments
- Azure Container Registry and all images
- Virtual Network
- Log Analytics workspace
- All node resource group resources

### Selective Cleanup

To keep some resources:

```bash
# Remove specific resources from state
terraform state rm azurerm_container_registry.acr[0]

# Then destroy
terraform destroy
```

### Manual Cleanup (if needed)

```bash
# Delete resource group
az group delete --name flask-video-streaming-rg --yes --no-wait

# Delete node resource group
az group delete --name MC_flask-video-streaming-rg_flask-video-aks_eastus --yes --no-wait
```

---

## Best Practices

### 1. Use Remote State

Store Terraform state in Azure Storage:

```bash
# Create storage
az storage account create \
  --resource-group terraform-state-rg \
  --name tfstate$(date +%s) \
  --sku Standard_LRS

# Configure backend in backend.tf
terraform init -backend-config="backend.conf"
```

### 2. Lock Terraform State

Enable state locking with Azure Storage:
```hcl
terraform {
  backend "azurerm" {
    # ... storage config ...
    use_msi = true
  }
}
```

### 3. Use Workspaces

Manage multiple environments:
```bash
# Create environments
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch environments
terraform workspace select prod
```

### 4. Validate Before Apply

```bash
# Format code
terraform fmt

# Validate syntax
terraform validate

# Check plan
terraform plan
```

### 5. Tag Resources

```hcl
tags = {
  Environment = "production"
  Project     = "flask-video-streaming"
  ManagedBy   = "Terraform"
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
```

---

## Outputs Reference

After deployment, Terraform provides useful outputs:

```bash
# Get all outputs
terraform output

# Specific outputs
terraform output cluster_name
terraform output acr_login_server
terraform output get_credentials_command

# Use in scripts
CLUSTER_NAME=$(terraform output -raw cluster_name)
RG_NAME=$(terraform output -raw resource_group_name)
```

---

## Next Steps

1. ✅ Deploy AKS cluster with Terraform
2. 📦 Build and push Docker image to ACR
3. 🚀 Deploy Flask application to Kubernetes
4. 📊 Configure monitoring and alerts
5. 🔒 Set up Azure AD authentication
6. 🌐 Configure custom domain (optional)
7. 📈 Performance testing and optimization

---

## Additional Resources

- [Terraform AzureRM Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## Support

For issues:
- **Terraform**: Check `terraform.log`
- **AKS**: Check Azure Portal diagnostics
- **Application**: See KUBERNETES_GUIDE.md
