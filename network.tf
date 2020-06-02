# root/network.tf 

# Create virtual network for everything
resource "azurerm_virtual_network" "tfnet" {
    name                = "tfvnet"
    address_space       = ["10.0.0.0/16"]
    location            = local.localregion
    resource_group_name = azurerm_resource_group.tfrg.name

    tags = {
        environment = "Temp"
    }
}

# Create subnet for worker client
resource "azurerm_subnet" "tfworkersubnet" {
    name                 = "tfworkersubnet"
    resource_group_name  = azurerm_resource_group.tfrg.name
    virtual_network_name = azurerm_virtual_network.tfnet.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create subnet for bastion
resource "azurerm_subnet" "tfbassubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.tfrg.name
  virtual_network_name = azurerm_virtual_network.tfnet.name
  address_prefixes       = ["10.0.2.0/24"]
}

# Create public IP for bastion
resource "azurerm_public_ip" "tfbaspubip" {
    name                         = "tfbaspubip"
    location                     = local.localregion
    resource_group_name          = azurerm_resource_group.tfrg.name
    allocation_method            = "Static"
    sku                          = "Standard"
    tags = {
        environment = "Temp"
    }
}

# Create public IP for worker
resource "azurerm_public_ip" "tfworkerpubip" {
    name                         = "tfworkerpubip"
    location                     = local.localregion
    resource_group_name          = azurerm_resource_group.tfrg.name
    allocation_method            = "Dynamic"
    tags = {
        environment = "Temp"
    }
}

# Create Network Security Group and rules for worker client
resource "azurerm_network_security_group" "tfworkernsg" {
    name                = "tfworkernsg"
    location            = local.localregion
    resource_group_name = azurerm_resource_group.tfrg.name
    tags = {
        environment = "Temp"
    }
}

resource "azurerm_network_security_rule" "aclw1" {
        name                       = "allow-rdp-in"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefixes      = [(jsondecode(data.http.geoipdata.body)).geoplugin_request,"10.0.2.0/24"]
        destination_address_prefix = "*"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfworkernsg.name
}

resource "azurerm_network_security_rule" "aclw2" {
        name                       = "allow-winrm-in"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5985"
        source_address_prefix      =  (jsondecode(data.http.geoipdata.body)).geoplugin_request
        destination_address_prefix = "*"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfworkernsg.name
} 

# Create Network Security Group and rules for bastion
resource "azurerm_network_security_group" "tfbastionnsg" {
    name                = "tfbastionnsg"
    location            = local.localregion
    resource_group_name = azurerm_resource_group.tfrg.name
}

resource "azurerm_network_security_rule" "aclb1" {
        name                        = "allow-443-in-client"
        priority                    = 1001
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "443"
        source_address_prefix       = (jsondecode(data.http.geoipdata.body)).geoplugin_request
        destination_address_prefix  = "*"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfbastionnsg.name
}

resource "azurerm_network_security_rule" "aclb2" { 
        name                        = "allow-443-in-gw"
        priority                    = 1002
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "443"
        source_address_prefix       = "GatewayManager"
        destination_address_prefix  = "*"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfbastionnsg.name
}

resource "azurerm_network_security_rule" "aclb3" {
        name                        = "allow-out-client"
        priority                    = 1003
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_ranges      = ["22","3389"]
        source_address_prefix       = "*"
        destination_address_prefix  = "VirtualNetwork"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfbastionnsg.name
}

resource "azurerm_network_security_rule" "aclb4" { 
        name                        = "allow-out-azurecloud"
        priority                    = 1004
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "443"
        source_address_prefix       = "*"
        destination_address_prefix  = "AzureCloud"
        resource_group_name         = azurerm_resource_group.tfrg.name
        network_security_group_name = azurerm_network_security_group.tfbastionnsg.name
}


# Create network interface for worker client
resource "azurerm_network_interface" "tfworkernic" {
    name                      = "tfworkernic"
    location                  = local.localregion
    resource_group_name       = azurerm_resource_group.tfrg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.tfworkersubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.tfworkerpubip.id 
    }

    tags = {
        environment = "Temp"
    }
}

# Connect the security group to the network interface - worker client
resource "azurerm_network_interface_security_group_association" "tfworkernicnsg" {
    network_interface_id      = azurerm_network_interface.tfworkernic.id
    network_security_group_id = azurerm_network_security_group.tfworkernsg.id
}

# Connect the security group to the network interface - bastion
resource "azurerm_subnet_network_security_group_association" "tfbastionsubnsg" {
    subnet_id      = azurerm_subnet.tfbassubnet.id
    network_security_group_id = azurerm_network_security_group.tfbastionnsg.id
}
