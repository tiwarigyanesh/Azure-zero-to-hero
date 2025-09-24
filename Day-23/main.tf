terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

variable "prefix" {
  default = "gt"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

provider "azurerm" {
  features {}
}

locals {
  rg_name   = "${var.prefix}-rg"
  vnet_name = "${var.prefix}-vnet"
  subnet_name = "${var.prefix}-subnet"
  pip_name  = "${var.prefix}-pip"
  nsg_name  = "${var.prefix}-nsg"
  nic_name  = "${var.prefix}-nic"
  vm_name   = "${var.prefix}-vm"
  nic_config_name = "${var.prefix}-nic-config"
  tags = {
    environment = "dev"
    owner       = "gyanesh"
  }
}

# ---------------------------
# Resource Group
# ---------------------------
resource "azurerm_resource_group" "example" {
  name     = local.rg_name
  location = "East US"
  tags     = local.tags
}

# ---------------------------
# Networking
# ---------------------------
resource "azurerm_virtual_network" "example" {
  name                = local.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = local.tags
}

resource "azurerm_subnet" "example" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = local.pip_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "example" {
  name                = local.nsg_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = local.tags

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "example" {
  name                = local.nic_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = local.tags

  ip_configuration {
    name                          = local.nic_config_name
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# ---------------------------
# Virtual Machine
# ---------------------------
resource "azurerm_linux_virtual_machine" "example" {
  name                = local.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  tags = local.tags

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ---------------------------
# Outputs
# ---------------------------
output "vm_public_ip" {
  value = azurerm_public_ip.example.ip_address
}
