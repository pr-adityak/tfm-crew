# Centralized naming for network resources
locals {
  subnet_names = {
    aks      = "${var.vnet_name}-aks-subnet"
    appgw    = "${var.vnet_name}-appgw-subnet"
    postgres = "${var.vnet_name}-postgres-subnet"
  }
  nsg_names = {
    aks      = "${var.vnet_name}-aks-nsg"
    appgw    = "${var.vnet_name}-appgw-nsg"
    postgres = "${var.vnet_name}-postgres-nsg"
  }
  nat_gateway_name    = "${var.vnet_name}-nat-gateway"
  nat_public_ip_name  = "${var.vnet_name}-nat-pip"
  appgw_public_ip_name = "${var.application_gateway_name}-pip"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

# AKS Node Subnet
resource "azurerm_subnet" "aks" {
  name                 = local.subnet_names.aks
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Application Gateway Subnet
resource "azurerm_subnet" "appgw" {
  name                 = local.subnet_names.appgw
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.appgw_subnet_address_prefix]
}

# PostgreSQL Delegated Subnet
resource "azurerm_subnet" "postgres" {
  name                 = local.subnet_names.postgres
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.postgres_subnet_address_prefix]

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Network Security Group - AKS
resource "azurerm_network_security_group" "aks" {
  name                = local.nsg_names.aks
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Security Group - Application Gateway
resource "azurerm_network_security_group" "appgw" {
  name                = local.nsg_names.appgw
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Security Group - PostgreSQL
resource "azurerm_network_security_group" "postgres" {
  name                = local.nsg_names.postgres
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG Association - AKS
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# NSG Association - Application Gateway
resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id

  depends_on = [
    azurerm_network_security_rule.appgw_http,
    azurerm_network_security_rule.appgw_https,
    azurerm_network_security_rule.appgw_infrastructure
  ]
}

# NSG Association - PostgreSQL
resource "azurerm_subnet_network_security_group_association" "postgres" {
  subnet_id                 = azurerm_subnet.postgres.id
  network_security_group_id = azurerm_network_security_group.postgres.id
}

# NSG Rule - Allow PostgreSQL from AKS
resource "azurerm_network_security_rule" "postgres_from_aks" {
  name                        = "allow-postgres-from-aks"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aks_subnet_address_prefix
  destination_address_prefix  = var.postgres_subnet_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.postgres.name
}

# NSG Rule - Allow HTTP to Application Gateway
resource "azurerm_network_security_rule" "appgw_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [azurerm_application_gateway.main]
}

# NSG Rule - Allow HTTPS to Application Gateway
resource "azurerm_network_security_rule" "appgw_https" {
  name                        = "allow-https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [azurerm_application_gateway.main]
}

# NSG Rule - Allow Azure Infrastructure Communication to Application Gateway
resource "azurerm_network_security_rule" "appgw_infrastructure" {
  name                        = "allow-azure-infrastructure"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [azurerm_application_gateway.main]
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  name                = local.nat_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

# NAT Gateway (zonal deployment - zone 2 to align with AKS nodes in zones 2,3)
resource "azurerm_nat_gateway" "main" {
  name                = local.nat_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  zones               = ["2"]

  tags = var.tags
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT Gateway with AKS Subnet
resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = local.appgw_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  zones = ["1", "2", "3"]

  sku {
    name = var.appgw_sku_name
    tier = var.appgw_sku_tier
  }

  autoscale_configuration {
    min_capacity = var.appgw_min_capacity
    max_capacity = var.appgw_max_capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "default-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "default-listener"
    frontend_ip_configuration_name = "public-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-http-settings"
    priority                   = 100
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      redirect_configuration,
      tags["managed-by-agic"],
      tags["managed-by-k8s-ingress"],
      tags["ingress-for-aks-cluster-id"]
    ]
  }

  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}
