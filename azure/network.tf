locals {
  tags = {
    project     = var.project_name
    environment = var.environment
  }

  name_prefix = "${var.project_name}-${var.environment}"

  # Dedicated subnet for the Application Gateway (see loadbalancer.tf) -
  # Application Gateway cannot share a subnet with other resource types.
  appgw_subnet_cidr = "10.0.2.0/24"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location

  tags = local.tags
}

# Azure has no "default VNet" concept - unlike DigitalOcean, this VNet is
# never auto-promoted to something un-deletable. `tofu destroy` removes the
# whole resource group (including this VNet) cleanly with no special
# handling required.
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = local.tags
}

resource "azurerm_subnet" "app" {
  name                 = "${local.name_prefix}-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- Network Security Group -------------------------------------------
# SSH is restricted to var.allowed_ssh_cidr (required, no default - the
# caller must set it). The three app ports are restricted to traffic from
# the Application Gateway's own subnet (see loadbalancer.tf) - the
# Application Gateway is now the only public entry point for app traffic,
# so the VMs no longer need their app ports open to the Internet directly.

resource "azurerm_network_security_group" "app" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-app-ports-from-appgw"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3000", "4000", "5000"]
    source_address_prefix      = local.appgw_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
