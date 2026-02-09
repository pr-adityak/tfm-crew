# User-Assigned Managed Identity for Cluster Control Plane
resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${var.cluster_name}-cluster-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# User-Assigned Managed Identity for Kubelet
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Grant AcrPull to kubelet identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

# Grant AcrPush to kubelet identity (for CI/CD workloads building images)
resource "azurerm_role_assignment" "acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

# Grant Key Vault Secrets User to kubelet identity
resource "azurerm_role_assignment" "kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

# Grant Storage Blob Data Contributor to kubelet identity (data storage)
resource "azurerm_role_assignment" "storage_data" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

# Grant Storage Blob Data Contributor to kubelet identity (logs storage)
resource "azurerm_role_assignment" "storage_logs" {
  scope                = var.logs_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

# Grant Managed Identity Operator to cluster identity for kubelet identity
resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "system"
    vm_size        = var.system_node_vm_size
    node_count     = var.system_node_count
    vnet_subnet_id = var.aks_subnet_id
    zones          = ["2", "3"]

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 5
    }
  }

  # Automatic patch upgrades for security fixes
  automatic_upgrade_channel = "patch"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    service_cidr        = "10.245.0.0/16"
    dns_service_ip      = "10.245.0.10"
    pod_cidr            = "10.244.0.0/16"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  # Enable workload identity for pod-to-Azure authentication
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # API server access - restrict to authorized IP ranges
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [4, 5]
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.kv_secrets,
    azurerm_role_assignment.storage_data,
    azurerm_role_assignment.storage_logs,
    azurerm_role_assignment.managed_identity_operator
  ]
}

# User Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = ["2", "3"]

  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 5
  }

  tags = merge(var.tags, {
    Role = "user-workloads"
  })
}
