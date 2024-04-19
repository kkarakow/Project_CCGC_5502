variable "location" {
  description = "The Azure location where resources will be created"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "N01459693-group"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network and Subnet
resource "azurerm_virtual_network" "main_vnet" {
  name                = "vmVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main_subnet" {
  name                 = "vmSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# SSH Public Key Data Source
data "azurerm_ssh_public_key" "main_key" {
  name                = "N01459693_key"
  resource_group_name = var.resource_group_name
}

# Public IPs for all VMs
resource "azurerm_public_ip" "vm_public_ip" {
  count               = 3 # Total VMs = 2 Linux VMs + 1 Windows VM
  name                = "vmPublicIP-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

# Network Interface for all VMs
resource "azurerm_network_interface" "vm_nic" {
  count = 3 # Total VMs = 2 Linux VMs + 1 Windows VM

  name                = "vmNIC-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip[count.index].id
  }
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count = 2

  name                  = "N01459693-c-vm${count.index + 1}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [element(azurerm_network_interface.vm_nic.*.id, count.index)]

 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 10  # Set OS disk size to 10 GB
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = data.azurerm_ssh_public_key.main_key.public_key
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                  = "N01459693-w-vm1"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "AComplexP@ssw0rd!"
  network_interface_ids = [azurerm_network_interface.vm_nic[2].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 10  
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Network Security Group to allow ICMP (ping)
resource "azurerm_network_security_group" "allow_icmp" {
  name                = "allow-icmp-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-inbound-icmp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # Add SSH rule
  security_rule {
    name                       = "allow-inbound-ssh"
    priority                   = 110 # Ensure this is unique and not conflicting with other priorities
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp" # SSH uses TCP
    source_port_range          = "*"
    destination_port_range     = "22" # Default SSH port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "allow-inbound-rdp"
    priority                   = 120 # Ensure this is unique and not conflicting with other priorities
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp" # RDP uses TCP
    source_port_range          = "*"
    destination_port_range     = "3389" # Default RDP port
    source_address_prefix      = "*"    # Allow any IP to access
    destination_address_prefix = "*"
  }
}


# Associate NSG with Network Interface of VMs
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg_association" {
  count                     = 3 # Assuming 3 VMs as per your setup
  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.allow_icmp.id
}
