variable "subscription_id" {
  type        = string
  description = "The ID of Azure subscription."
  default     = ""
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. If this value isn't null (the default), 'data.azurerm_client_config.current.object_id' will be set to this value."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group that will contain all created resources."
  default     = "GemBoxSigningGroup"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault that will be used to store certificates."
  default     = "gemboxsigningvault"
}

variable "container_group_name" {
  type        = string
  description = "The name of the container group."
  default     = "gembox-signing-container-group"
}

variable "container_name" {
  type        = string
  description = "The name of the container."
  default     = "gembox-signing-container"
}


variable "https_certificate_path" {
  type        = string
  description = "Certificate used for HTTPS traffic. If this value is null, only HTTP will work."
  default     = "./certificates/https.pfx"
}

variable "https_certificate_password" {
  type        = string
  description = "Password for the certificate used for HTTPS traffic."
  default     = "password"
}

variable "signing_certificate_path" {
  type        = string
  description = "Certificate used for signing."
  default     = "./certificates/signing.pfx"
}

variable "signing_certificate_password" {
  type        = string
  description = "Password for the certificate used for signing."
  default     = "GemBoxPassword"
}

variable "allow_origins" {
  type        = string
  description = "Comma-separated list of allowed origins for the web application."
  default     = "*" # You should restrict this to only the origins you need.
}

variable "api_password" {
  type        = string
  description = "The API key that will be used to authenticate the signing request. If the value is null, no API key is needed for the authentication."
  default     = null 
}

variable "http_port" {
  type        = number
  description = "Port to open for HTTP on the container and the public IP address."
  default     = 80 
}

variable "https_port" {
  type        = number
  description = "Port to open for HTTPS on the container and the public IP address."
  default     = 443
}

variable "gembox_pdf_license_key" {
  type        = string
  description = "The license key for GemBox.Pdf."
  default     = "FREE-LIMITED-KEY"
}