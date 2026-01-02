variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "flask-video-streaming-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "flask-video-aks"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "flask-video"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "network_plugin" {
  description = "Network plugin to use (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use (calico or azure)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.1.0.10"
}

# System Node Pool Configuration (Minimum 3 nodes)
variable "system_node_count" {
  description = "Number of nodes in the system node pool (minimum 3)"
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_count >= 3
    error_message = "System node pool must have at least 3 nodes for high availability."
  }
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_os_disk_size" {
  description = "OS disk size in GB for system nodes"
  type        = number
  default     = 128
}

variable "system_node_min_count" {
  description = "Minimum number of system nodes (for auto-scaling)"
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_min_count >= 3
    error_message = "System node pool must have at least 3 nodes for high availability."
  }
}

variable "system_node_max_count" {
  description = "Maximum number of system nodes (for auto-scaling)"
  type        = number
  default     = 6
}

# User Node Pool Configuration
variable "user_node_count" {
  description = "Number of nodes in the user node pool"
  type        = number
  default     = 3
}

variable "user_node_vm_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "user_node_os_disk_size" {
  description = "OS disk size in GB for user nodes"
  type        = number
  default     = 128
}

variable "user_node_min_count" {
  description = "Minimum number of user nodes (for auto-scaling)"
  type        = number
  default     = 3
}

variable "user_node_max_count" {
  description = "Maximum number of user nodes (for auto-scaling)"
  type        = number
  default     = 10
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 110
}

# Auto Scaling
variable "enable_auto_scaling" {
  description = "Enable auto-scaling for node pools"
  type        = bool
  default     = true
}

# Azure AD Integration
variable "enable_azure_ad_integration" {
  description = "Enable Azure AD integration"
  type        = bool
  default     = true
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups for cluster admin access"
  type        = list(string)
  default     = []
}

# Monitoring
variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

# Container Registry
variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

# Additional Features
variable "enable_http_application_routing" {
  description = "Enable HTTP application routing add-on"
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = false
}

# Maintenance Window
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day   = string
    hours = list(number)
  })
  default = null
  # Example:
  # {
  #   day   = "Sunday"
  #   hours = [0, 1, 2, 3]
  # }
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Application = "Flask-Video-Streaming"
    Project     = "Video-Platform"
  }
}
