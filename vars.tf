# Variables File - /root/vars.tf ##

# Variable to enable auto region select
variable "enable_autoregion" {
  description = "If set to true, enable auto region choosing"
  type        = bool
  default     = true
}

variable "autoregion_selected" {
 type        = string
 description = "Region selected automatically"
 default     = null
}

# This maps country code to azure region
variable "regionmap" {
  type = map(string)
  default = {
    "MY" = "westus2"
    "US" = "westus2"
  }
}

# This matches the country code to to the map above to return the desired azure region if the enable_autoregion var is true, otherwise defaults to eastus
locals {
localregion = var.enable_autoregion == true ? var.regionmap[(jsondecode(data.http.geoipdata.body)).geoplugin_countryCode] : "eastus"
}

variable vmname {
type        = string
description = "Provide a name for the vm"
default     = "tfvm"
}

variable "dsc_key" {
  default = "yourdsckeyhere"
}

variable "dsc_endpoint" {
  default = "https://wus2-agentservice-prod-1.azure-automation.net/accounts/restofyoururlhere"
}

variable dsc_config {
  default = "TestConfig.IsServer"
}
variable dsc_mode {
  default = "applyAndMonitor"
}

