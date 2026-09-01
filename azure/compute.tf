locals {
  apps = {
    node = {
      port       = 3000
      cloud_init = "../apps/node/cloud-init.yaml.tpl"
      source     = "../apps/node/server.js"
      router     = null
      extra_env  = var.node_env
    }
    python = {
      port       = 4000
      cloud_init = "../apps/python/cloud-init.yaml.tpl"
      source     = "../apps/python/server.py"
      router     = null
      extra_env  = var.python_env
    }
    php = {
      port       = 5000
      cloud_init = "../apps/php/cloud-init.yaml.tpl"
      source     = "../apps/php/index.php"
      router     = "../apps/php/router.php"
      extra_env  = var.php_env
    }
  }
}

# Basic-SKU public IPs were retired by Azure on 30 September 2025; Standard
# SKU + Static allocation is now required for new public IPs.
resource "azurerm_public_ip" "app" {
  for_each = local.apps

  name                = "${local.name_prefix}-${each.key}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.tags, { app = each.key })
}

resource "azurerm_network_interface" "app" {
  for_each = local.apps

  name                = "${local.name_prefix}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app[each.key].id
  }

  tags = merge(local.tags, { app = each.key })
}

resource "azurerm_linux_virtual_machine" "app" {
  for_each = local.apps

  name                = "${local.name_prefix}-${each.key}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.app[each.key].id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Renders the shared, dependency-free status app for this language and
  # wires it to the managed MySQL/Redis endpoints (plus any custom
  # node_env/python_env/php_env vars) via a generated env file, following
  # the fixed contract documented in ../apps/README.md. PHP additionally
  # needs app_router_b64 (its built-in-server router script, required for
  # path-based routing through the Application Gateway - see
  # ../apps/README.md and loadbalancer.tf).
  custom_data = base64encode(templatefile(each.value.cloud_init, merge(
    {
      app_port       = each.value.port
      app_source_b64 = filebase64(each.value.source)
      app_env_b64 = base64encode(join("\n", [
        for k, v in merge({
          APP_PORT   = tostring(each.value.port)
          MYSQL_HOST = azurerm_mysql_flexible_server.main.fqdn
          MYSQL_PORT = "3306"
          REDIS_HOST = azurerm_redis_cache.main.hostname
          REDIS_PORT = tostring(azurerm_redis_cache.main.ssl_port)
        }, each.value.extra_env) : "${k}=${v}"
      ]))
    },
    each.value.router != null ? { app_router_b64 = filebase64(each.value.router) } : {}
  )))

  tags = merge(local.tags, { app = each.key })

  depends_on = [
    azurerm_subnet_network_security_group_association.app,
    azurerm_mysql_flexible_server_firewall_rule.azure_services,
    azurerm_mysql_flexible_server_firewall_rule.app_vms,
    azurerm_redis_firewall_rule.app_vms,
  ]
}
