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
