# Application Gateway (Standard_v2, HTTP only) providing a single public
# entry point that path-routes to the three app VMs:
#   /nodejs*   -> node   (port 3000)
#   /python*   -> python (port 4000)
#   /php*      -> php    (port 5000)
#
# Application Gateway cannot share a subnet with any other resource type, so
# it gets its own dedicated subnet (local.appgw_subnet_cidr, defined in
# network.tf) and its own Network Security Group.

resource "azurerm_subnet" "appgw" {
  name                 = "${local.name_prefix}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.appgw_subnet_cidr]
}

# v2-SKU Application Gateways require inbound access from the "GatewayManager"
# service tag on ports 65200-65535 for Azure's control plane to manage the
# gateway - without this rule the gateway fails to provision/update. The
# AzureLoadBalancer rule is Microsoft's other standard recommendation for
# this subnet (infrastructure health probes). Port 80 from the Internet is
# the actual application traffic.
resource "azurerm_network_security_group" "appgw" {
  name                = "${local.name_prefix}-appgw-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-gateway-manager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-azure-load-balancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

resource "azurerm_public_ip" "appgw" {
  name                = "${local.name_prefix}-appgw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_application_gateway" "main" {
  name                = "${local.name_prefix}-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Fixed capacity (no autoscaling) - simplest, cheapest configuration for a
  # starter. Bump capacity or switch to an autoscale_configuration block for
  # real traffic.
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # One backend pool + HTTP settings per app, targeting that VM's private IP
  # directly (the app VMs are single instances, not an instance group).
  dynamic "backend_address_pool" {
    for_each = local.apps
    content {
      name         = "${backend_address_pool.key}-pool"
      ip_addresses = [azurerm_network_interface.app[backend_address_pool.key].private_ip_address]
    }
  }

  dynamic "backend_http_settings" {
    for_each = local.apps
    content {
      name                  = "${backend_http_settings.key}-settings"
      cookie_based_affinity = "Disabled"
      port                  = backend_http_settings.value.port
      protocol              = "Http"
      request_timeout       = 30
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  url_path_map {
    name = "path-map"
    # Falls back to the Node.js backend for any path that doesn't match a
    # rule below (e.g. the bare "/") - a convenience, not the documented
    # contract. The documented, symmetric way to reach each app is
    # /nodejs*, /python*, /php*.
    default_backend_address_pool_name  = "node-pool"
    default_backend_http_settings_name = "node-settings"

    path_rule {
      name                       = "node-path"
      paths                      = ["/nodejs*"]
      backend_address_pool_name  = "node-pool"
      backend_http_settings_name = "node-settings"
    }

    path_rule {
      name                       = "python-path"
      paths                      = ["/python*"]
      backend_address_pool_name  = "python-pool"
      backend_http_settings_name = "python-settings"
    }

    path_rule {
      name                       = "php-path"
      paths                      = ["/php*"]
      backend_address_pool_name  = "php-pool"
      backend_http_settings_name = "php-settings"
    }
  }

  request_routing_rule {
    name               = "path-based-rule"
    priority           = 100
    rule_type          = "PathBasedRouting"
    http_listener_name = "http-listener"
    url_path_map_name  = "path-map"
  }

  tags = local.tags

  depends_on = [
    azurerm_subnet_network_security_group_association.appgw,
  ]
}
