# root/compute.tf

# Create bastion host
resource "azurerm_bastion_host" "tfbastion" {
  name                = "tfbastion"
  location            = local.localregion
  resource_group_name = azurerm_resource_group.tfrg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.tfbassubnet.id
    public_ip_address_id = azurerm_public_ip.tfbaspubip.id
  }
}

# Create worker virtual machine
resource "azurerm_windows_virtual_machine" "tfvm" {
    name                  = var.vmname
    resource_group_name   = azurerm_resource_group.tfrg.name
    location              = azurerm_resource_group.tfrg.location
    size                  = "Basic_A2"
    admin_username        = data.azurerm_key_vault_secret.localadmin.name
    admin_password        = data.azurerm_key_vault_secret.localadmin.value
    network_interface_ids = [azurerm_network_interface.tfworkernic.id,]
    
    os_disk {
    caching = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
    }

    source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
    }

    tags = {
        environment = "Temp"
    }
}

resource "azurerm_virtual_machine_extension" "dscext" {
  name                 = "dscext"
  virtual_machine_id   = azurerm_windows_virtual_machine.tfvm.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  depends_on           = [azurerm_windows_virtual_machine.tfvm]

  settings = <<SETTINGS
        {
            "WmfVersion": "latest",
            "Privacy": {
                "DataCollection": ""
            },
            "advancedOptions": {
                "forcePullAndApply": false
            },
            "Properties": {
                "RegistrationKey": {
                  "UserName": "PLACEHOLDER_DONOTUSE",
                  "Password": "PrivateSettingsRef:registrationKeyPrivate"
                },
                "RegistrationUrl": "${var.dsc_endpoint}",
                "NodeConfigurationName": "${var.dsc_config}",
                "ConfigurationMode": "${var.dsc_mode}",
                "ConfigurationModeFrequencyMins": 15,
                "RefreshFrequencyMins": 30,
                "RebootNodeIfNeeded": true,
                "ActionAfterReboot": "continueConfiguration",
                "AllowModuleOverwrite": false
            }
        }
    SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Items": {
        "registrationKeyPrivate" : "${var.dsc_key}"
      }
    }
PROTECTED_SETTINGS

 timeouts {
    create = "60m"
    delete = "15m"
 }
}
