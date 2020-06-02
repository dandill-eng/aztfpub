
#data "azurerm_public_ip" "tfworkerpubipdata" {
#  name                = azurerm_public_ip.tfworkerpubip.name
#  resource_group_name = azurerm_windows_virtual_machine.tfvm.resource_group_name
#}

#output "public_ip_address2" {
#  value = data.azurerm_public_ip.tfworkerpubipdata.ip_address
#  description = "Worker Pub ip"
#}

output "vm" {
  value = azurerm_windows_virtual_machine.tfvm.name
  description = "VM Name"
}

output "os" {
value = "${azurerm_windows_virtual_machine.tfvm.source_image_reference.0.offer}_${azurerm_windows_virtual_machine.tfvm.source_image_reference.0.sku}"
}

output "region" {
  value = local.localregion
}

output "myinetip"{
value = (jsondecode(data.http.geoipdata.body)).geoplugin_request
description = "This is the terraform machine ext ipv4 - used for ACLs"
}

