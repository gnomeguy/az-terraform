# Configure the Azure provider
provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "az104-10-rg0"
  location = "West US 2"
}

resource "azurerm_virtual_network" "main" {
  name                = "az104-10-vnet0"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "test" {
  count               = 2
  name                = "ForRDP${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "main" {
  count               = 2
  name                = "az104-10-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test[count.index].id
  }
}

  resource "azurerm_windows_virtual_machine" "main" {
  count               = 2
  name                = "az104-10-vm${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  admin_username      = "student"
  admin_password      = "Pa55w.rd1234"
  size                = "Standard_F2"
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "azurerm_recovery_services_vault" "example" {
  name                = "az104-10-rsv1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  soft_delete_enabled = false
}

resource "azurerm_backup_policy_vm" "example" {
  name                = "az104-10-backup-policy"
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name

  timezone = "Central Europe Standard Time"

  backup {
    frequency = "Daily"
    time      = "00:00"
  }
   retention_daily {
    count = 180
  }

}

resource "azurerm_backup_protected_vm" "vm1" {
  count               = 1  
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  source_vm_id        = azurerm_windows_virtual_machine.main[count.index].id
  backup_policy_id    = azurerm_backup_policy_vm.example.id
}