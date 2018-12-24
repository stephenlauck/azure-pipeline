provider "azurerm" {
	 
}

resource "azurerm_resource_group" "pipelinegroup" {
  name = "solaris"
  location = "eastus"

}

resource "azurerm_virtual_network" "pipelinenetwork" {
  name = "solarisVnet"
  address_space = ["10.0.0.0/16"]
  location = "eastus"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
}

resource "azurerm_subnet" "pipelinesubnet" {
  name = "solarisSubnet"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.pipelinenetwork.name}"
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "pipelinepublicip" {
  name = "solarisIP"
  location = "eastus"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_security_group" "pipelinesg" {
  name = "solarisNetworkSecurityGroup"
  location = "eastus"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"

  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "pipelinenic"{
  name = "solarisNIC"
  location = "eastus"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.pipelinesg.id}"

  ip_configuration {
    name = "solarisNicConfiguration"
    subnet_id = "${azurerm_subnet.pipelinesubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.pipelinepublicip.id}"
  }
}

resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.pipelinegroup.name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "pipelinestorageaccount" {
  name                = "diag${random_id.randomId.hex}"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
  location            = "eastus"
  account_replication_type = "LRS"
  account_tier = "Standard"
}

resource "azurerm_virtual_machine" "pipelinevm" {
  name = "solarisVM"
  location = "eastus"
  resource_group_name = "${azurerm_resource_group.pipelinegroup.name}"
  network_interface_ids = ["${azurerm_network_interface.pipelinenic.id}"]
  vm_size = "Standard_D2s_v3"

  storage_os_disk {
    name = "solarisOsDisk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "solarisvm"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa"
    }
  }
}
