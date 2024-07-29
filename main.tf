provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks" {
  name     = "aksResGroup"
  location = "East US 2"
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

resource "time_sleep" "wait_for_vnet" {
  depends_on = [azurerm_virtual_network.aks_vnet]
  create_duration = "30s"
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.0.0/16"]

  depends_on = [
    azurerm_virtual_network.aks_vnet,
    time_sleep.wait_for_vnet
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on          = [azurerm_virtual_network.aks_vnet, azurerm_subnet.aks_subnet]
  name                = "desafioDevOps"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "desafiodevops"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"

    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Development"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.host
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  sensitive = true
}
