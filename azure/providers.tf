# Authentication is resolved via the Azure CLI (`az login`) or standard
# ARM_* environment variables (ARM_SUBSCRIPTION_ID, ARM_TENANT_ID,
# ARM_CLIENT_ID, ARM_CLIENT_SECRET for a service principal). No subscription
# ID or credentials are hardcoded here on purpose.
provider "azurerm" {
  features {}
}
