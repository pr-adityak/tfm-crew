# Managed Identity for AGIC
resource "azurerm_user_assigned_identity" "agic" {
  name                = "${var.cluster_name}-agic-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Grant Contributor on Application Gateway
resource "azurerm_role_assignment" "agic_appgw" {
  scope                = var.application_gateway_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

# Grant Reader on resource group
resource "azurerm_role_assignment" "agic_rg" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

# Grant Network Contributor on VNet
resource "azurerm_role_assignment" "agic_network" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

# Platform Namespace
resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
  }
}

# Database Secret
resource "kubernetes_secret" "database" {
  metadata {
    name      = var.database_secret_name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    host     = var.db_host
    port     = tostring(var.db_port)
    database = var.db_name
    username = var.db_username
    password = var.db_password
  }

  type = "Opaque"
}

# Federated Identity Credential for AGIC
# The AGIC Helm chart creates its own service account named "${release_name}-sa-ingress-azure"
# with workload identity annotations when armAuth.type=workloadIdentity is set
locals {
  agic_release_name         = "agic"
  agic_service_account_name = "${local.agic_release_name}-sa-ingress-azure"
}

resource "azurerm_federated_identity_credential" "agic" {
  name                = "agic-federated-identity"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.agic.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:kube-system:${local.agic_service_account_name}"
}

# AGIC Helm Release
# Deployed to kube-system as AGIC is a cluster-wide ingress controller
# The chart creates its own service account with workload identity annotations
resource "helm_release" "agic" {
  name       = local.agic_release_name
  repository = "oci://mcr.microsoft.com/azure-application-gateway/charts"
  chart      = "ingress-azure"
  version    = var.agic_helm_version
  namespace  = "kube-system"

  set {
    name  = "appgw.subscriptionId"
    value = var.subscription_id
  }

  set {
    name  = "appgw.resourceGroup"
    value = var.resource_group_name
  }

  set {
    name  = "appgw.name"
    value = var.application_gateway_name
  }

  set {
    name  = "appgw.shared"
    value = "false"
  }

  set {
    name  = "armAuth.type"
    value = "workloadIdentity"
  }

  set {
    name  = "armAuth.identityClientID"
    value = azurerm_user_assigned_identity.agic.client_id
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }

  set {
    name  = "verbosityLevel"
    value = "3"
  }

  depends_on = [
    azurerm_role_assignment.agic_appgw,
    azurerm_federated_identity_credential.agic,
    azurerm_role_assignment.agic_rg,
    azurerm_role_assignment.agic_network
  ]
}
