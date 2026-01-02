terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Virtual Network
resource "azurerm_virtual_network" "aks" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = [var.vnet_address_space]

  tags = var.tags
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.subnet_address_prefix]
}

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  tags = var.tags
}

# Role Assignment for AKS Identity on Subnet
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${var.cluster_name}-law"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = var.tags
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  count               = var.create_acr ? 1 : 0
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = var.tags
}

# Role Assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.create_acr ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # System Node Pool (minimum 3 nodes)
  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_node_vm_size
    os_disk_size_gb     = var.system_node_os_disk_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.system_node_min_count : null
    max_count           = var.enable_auto_scaling ? var.system_node_max_count : null
    max_pods            = var.max_pods_per_node
    os_sku              = "Ubuntu"
    type                = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # Azure AD Integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_integration ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = var.enable_azure_rbac
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Monitoring
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
    }
  }

  # Auto Scaler Profile
  dynamic "auto_scaler_profile" {
    for_each = var.enable_auto_scaling ? [1] : []
    content {
      balance_similar_node_groups      = true
      expander                         = "random"
      max_graceful_termination_sec     = 600
      max_node_provisioning_time       = "15m"
      max_unready_nodes                = 3
      max_unready_percentage           = 45
      new_pod_scale_up_delay           = "10s"
      scale_down_delay_after_add       = "10m"
      scale_down_delay_after_delete    = "10s"
      scale_down_delay_after_failure   = "3m"
      scan_interval                    = "10s"
      scale_down_unneeded              = "10m"
      scale_down_unready               = "20m"
      scale_down_utilization_threshold = "0.5"
    }
  }

  # HTTP Application Routing (optional)
  http_application_routing_enabled = var.enable_http_application_routing

  # Azure Policy (optional)
  azure_policy_enabled = var.enable_azure_policy

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [1] : []
    content {
      allowed {
        day   = var.maintenance_window.day
        hours = var.maintenance_window.hours
      }
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_subnet
  ]
}

# User Node Pool for Application Workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  os_disk_size_gb       = var.user_node_os_disk_size
  vnet_subnet_id        = azurerm_subnet.aks.id
  enable_auto_scaling   = var.enable_auto_scaling
  min_count             = var.enable_auto_scaling ? var.user_node_min_count : null
  max_count             = var.enable_auto_scaling ? var.user_node_max_count : null
  max_pods              = var.max_pods_per_node
  os_type               = "Linux"
  os_sku                = "Ubuntu"
  mode                  = "User"

  upgrade_settings {
    max_surge = "10%"
  }

  node_labels = {
    "workload" = "application"
  }

  tags = var.tags
}

# Note: LoadBalancer services in AKS automatically create and manage their own
# public IPs in the node resource group. No need to pre-create a public IP resource.

