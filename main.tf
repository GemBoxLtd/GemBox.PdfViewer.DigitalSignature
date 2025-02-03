data "azurerm_client_config" "current" {}

locals {
  current_user_id = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "eastus2"
}

resource "azurerm_key_vault" "keyvault" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "terraform_keyvault_certificate_access" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = local.current_user_id
}

resource "azurerm_key_vault_secret" "https_certificate_secret" {
  name         = "gembox-https-certificate"
  value        = var.https_certificate_path != null ? filebase64(var.https_certificate_path) : ""
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [azurerm_role_assignment.terraform_keyvault_certificate_access]
}

resource "azurerm_key_vault_secret" "https_certificate_password_secret" {
  name         = "gembox-https-certificate-password"
  value        = var.https_certificate_password != null ? var.https_certificate_password : ""
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [azurerm_role_assignment.terraform_keyvault_certificate_access]
}

resource "azurerm_key_vault_secret" "signing_certificate_secret" {
  name         = "gembox-signing-certificate"
  value        = filebase64(var.signing_certificate_path)
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [azurerm_role_assignment.terraform_keyvault_certificate_access]
}

resource "azurerm_key_vault_secret" "signing_certificate_password_secret" {
  name         = "gembox-signing-certificate-password"
  value        = var.signing_certificate_password
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [azurerm_role_assignment.terraform_keyvault_certificate_access]
}

resource "azurerm_user_assigned_identity" "container_identity" {
  name                = "gembox-signing-container-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "keyvault_certificate_access" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
}

resource "azurerm_container_group" "container_group" {
  name                			= var.container_group_name
  location            			= azurerm_resource_group.rg.location
  resource_group_name 			= azurerm_resource_group.rg.name
  dns_name_label 	  			= "gembox-signing-service"
  dns_name_label_reuse_policy 	= "Noreuse"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.container_identity.id
    ]
  }

  container {
    name   			= var.container_name
    image  			= "gembox/signing-service:latest"
    cpu    			= 1
    memory 			= 1

    ports {
      port     = var.http_port
      protocol = "TCP"
    }

    ports {
      port     = var.https_port
      protocol = "TCP"
    }

    environment_variables = {
      AZURE_KEY_VAULT_URI           					= azurerm_key_vault.keyvault.vault_uri
      AZURE_HTTPS_CERTIFICATE_SECRET_NAME     			= azurerm_key_vault_secret.https_certificate_secret.name
      AZURE_HTTPS_CERTIFICATE_PASSWORD_SECRET_NAME 		= azurerm_key_vault_secret.https_certificate_password_secret.name
      AZURE_SIGNING_CERTIFICATE_SECRET_NAME   			= azurerm_key_vault_secret.signing_certificate_secret.name
      AZURE_SIGNING_CERTIFICATE_PASSWORD_SECRET_NAME 	= azurerm_key_vault_secret.signing_certificate_password_secret.name
	  ALLOW_ORIGINS 									= var.allow_origins
	  GEMBOX_PDF_LICENSE_KEY							= var.gembox_pdf_license_key
	  API_PASSWORD										= var.api_password
	  HTTP_PORTS										= var.http_port
	  HTTPS_PORTS										= var.https_port
    }
  }

  os_type = "Linux"
}