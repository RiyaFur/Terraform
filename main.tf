resource "azurerm_resource_group" "Demo" {
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.Demo.location
  resource_group_name = azurerm_resource_group.Demo.name
}

resource "azurerm_subnet" "internal" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.Demo.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/28"]
}
resource "azurerm_public_ip" "exampleIp" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.Demo.name
  location            = azurerm_resource_group.Demo.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main_network_interface" {
  name                = "Terraform-nic"
  location            = azurerm_resource_group.Demo.location
  resource_group_name = azurerm_resource_group.Demo.name

  ip_configuration {
    name                          = "terraformconfiguration"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.exampleIp.id
  }
}

resource "azurerm_network_security_group" "exampleNSG" {
  name                = "TerraformSecurityGroup"
  location            = azurerm_resource_group.Demo.location
  resource_group_name = azurerm_resource_group.Demo.name

  security_rule {
    name                       = "terraform123"
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
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id                 = azurerm_network_interface.main_network_interface.id
  network_security_group_id            = azurerm_network_security_group.exampleNSG.id
} 

resource "azurerm_virtual_machine" "main" {
  name                  = var.virtual_machine_name
  location              = azurerm_resource_group.Demo.location
  resource_group_name   = azurerm_resource_group.Demo.name
  network_interface_ids = [azurerm_network_interface.main_network_interface.id]
  vm_size               = "Standard_D2s_v3"  # "Standard_D2ls_v5" #Standard D2s v3 (2 vcpus, 8 GiB memory)

  #Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "testing"
  }
}
