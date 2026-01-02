output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aks.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.aks.location
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "node_resource_group" {
  description = "Name of the node resource group"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "system_node_pool_name" {
  description = "Name of the system node pool"
  value       = azurerm_kubernetes_cluster.aks.default_node_pool[0].name
}

output "system_node_count" {
  description = "Number of nodes in the system node pool"
  value       = azurerm_kubernetes_cluster.aks.default_node_pool[0].node_count
}

output "user_node_pool_name" {
  description = "Name of the user node pool"
  value       = azurerm_kubernetes_cluster_node_pool.user.name
}

output "user_node_count" {
  description = "Number of nodes in the user node pool"
  value       = azurerm_kubernetes_cluster_node_pool.user.node_count
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.aks.id
}

output "subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].id : null
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].login_server : null
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].name : null
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.aks[0].id : null
}

output "identity_principal_id" {
  description = "Principal ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "identity_client_id" {
  description = "Client ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# Connection Commands
output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "acr_login_command" {
  description = "Command to login to ACR"
  value       = var.create_acr ? "az acr login --name ${azurerm_container_registry.acr[0].name}" : null
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "export KUBECONFIG=<(terraform output -raw kube_config)"
}

# Deployment Information
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    cluster_name           = azurerm_kubernetes_cluster.aks.name
    resource_group         = azurerm_resource_group.aks.name
    location               = azurerm_resource_group.aks.location
    kubernetes_version     = azurerm_kubernetes_cluster.aks.kubernetes_version
    system_node_count      = azurerm_kubernetes_cluster.aks.default_node_pool[0].node_count
    user_node_count        = azurerm_kubernetes_cluster_node_pool.user.node_count
    total_nodes            = azurerm_kubernetes_cluster.aks.default_node_pool[0].node_count + azurerm_kubernetes_cluster_node_pool.user.node_count
    acr_enabled            = var.create_acr
    log_analytics_enabled  = var.enable_log_analytics
    auto_scaling_enabled   = var.enable_auto_scaling
  }
}
