provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "networkFortresource" {
  name     = "networkFortresource"
  location = "East US"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.networkFortresource.location
  resource_group_name = azurerm_resource_group.networkFortresource.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.networkFortresource.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicIP" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.networkFortresource.location
  resource_group_name = azurerm_resource_group.networkFortresource.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.networkFortresource.location
  resource_group_name = azurerm_resource_group.networkFortresource.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIP.id
  }
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "myVM"
  location            = azurerm_resource_group.networkFortresource.location
  resource_group_name = azurerm_resource_group.networkFortresource.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                = "Standard_B1s"  # Approximate size for 2 GB RAM, check Azure's VM size documentation for specifics

  admin_username      = "ubuntu"
  admin_password      = "NetworkFort123!"  # Ensure this is a secure password in production
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"  # Or the version you prefer
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install zeek suricata -y"
    ]

    connection {
      type     = "ssh"
      user     = "ubuntu"
      password = "NetworkFort123!"  # Consider using a more secure method in production
      host     = azurerm_public_ip.publicIP.ip_address
    }
  }
}
