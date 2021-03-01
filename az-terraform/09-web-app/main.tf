# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "az104-09a-rg1"
  location = "West US 2"
}

resource "azurerm_app_service_plan" "example" {
  name                = "09a-appsvcplan104"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "example" {
  name                = "09a-app-svc"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

resource "azurerm_app_service_slot" "example" {
    name                = "09aslotone"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    app_service_plan_id = azurerm_app_service_plan.example.id
    app_service_name    = azurerm_app_service.example.name
}


  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
}