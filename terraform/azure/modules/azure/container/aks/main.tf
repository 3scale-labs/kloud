provider "azuread" {
  version = "~> 0.3"
}

resource "azuread_application" "aks_app" {
  name = "${var.name}-app"
}

# Create a Service Principal for AKS
resource "azuread_service_principal" "aks_sp" {
  application_id = "${azuread_application.aks_app.application_id}"
}


# Create a password for the Service Principal used by AKS
resource "random_string" "aks_sp_password" {
  length  = 16
  special = true

  keepers = {
    service_principal = "${azuread_service_principal.aks_sp.id}"
  }
}

resource "azuread_service_principal_password" "aks_sp_password" {
  service_principal_id = "${azuread_service_principal.aks_sp.id}"
  value                = "${random_string.aks_sp_password.result}"
  end_date             = "${timeadd(timestamp(), "8760h")}"

  # This stops be 'end_date' changing on each run and causing a new password to be set
  # to get the date to change here you would have to manually taint this resource...
  lifecycle {
    ignore_changes = ["end_date"]
  }
}

data "azurerm_subscription" "main" {}

# Create a role for the Service Principal used by AKS
resource "azurerm_role_definition" "aks_sp_role_rg" {
  name        = "aks_sp_role"
  scope       = "${data.azurerm_subscription.main.id}"
  description = "This role provides the required permissions needed by Kubernetes to: Manager VMs, Routing rules, Mount azure files and Read container repositories"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Network/routeTables/routes/delete",
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
    ]

    not_actions = [
      // Deny access to all VM actions, this includes Start, Stop, Restart, Delete, Redeploy, Login, Extensions etc
      "Microsoft.Compute/virtualMachines/*/action",
      "Microsoft.Compute/virtualMachines/extensions/*",
    ]
  }

  assignable_scopes = [
    "${data.azurerm_subscription.main.id}",
  ]
}

# Create virtual network (VNet)
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-aks-network"
  location            = "${var.resource_group.location}"
  resource_group_name = "${var.resource_group.name}"
  address_space       = ["10.240.0.0/16"]
}

# Create AKS subnet to be used by nodes and pods
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = "${var.resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.240.0.0/20"
}

# Create Virtual Node (ACI) subnet
resource "azurerm_subnet" "aci" {
  name                 = "aci-subnet"
  resource_group_name  = "${var.resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.240.16.0/20"

  # Designate subnet to be used by ACI
  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Grant AKS cluster access to join AKS subnet
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = "${azurerm_subnet.aks.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.aks_sp.id}"
}

# Grant AKS cluster access to join ACI subnet
resource "azurerm_role_assignment" "aci_subnet" {
  scope                = "${azurerm_subnet.aci.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.aks_sp.id}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.name}-aks"
  location            = "${var.resource_group.location}"
  resource_group_name = "${var.resource_group.name}"
  node_resource_group = "${var.resource_group.name}-nodes"
  dns_prefix          = "${var.name}-aks"
  kubernetes_version  = "${var.kubernetes_version}"

  agent_pool_profile {
    name                = "addonspool"
    type                = "VirtualMachineScaleSets"
    min_count           = 1
    max_count           = 1
    enable_auto_scaling = true
    vm_size             = "${var.vm_size}"
    os_type             = "Linux"
    vnet_subnet_id      = "${azurerm_subnet.aks.id}"
    os_disk_size_gb     = 30
    node_taints = [
      "CriticalAddonsOnly=true:NoSchedule"
    ]
  }

  agent_pool_profile {
    name                = "computepool"
    type                = "VirtualMachineScaleSets"
    min_count           = 1
    max_count           = 3
    enable_auto_scaling = true
    vm_size             = "${var.vm_size}"
    os_type             = "Linux"
    vnet_subnet_id      = "${azurerm_subnet.aks.id}"
    os_disk_size_gb     = 30
  }

  addon_profile {
    # Enable virtual node (ACI connector) for Linux
    aci_connector_linux {
      enabled     = true
      subnet_name = "${azurerm_subnet.aci.name}"
    }

    http_application_routing {
      enabled = true
    }
  }

  network_profile {
    network_plugin = "azure"
  }

  role_based_access_control {
    enabled = true
  }

  service_principal {
    client_id     = "${azuread_service_principal.aks_sp.application_id}"
    client_secret = "${random_string.aks_sp_password.result}"
  }

}
