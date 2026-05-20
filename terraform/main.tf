terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

# ── Resource Group ───────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ── Cluster AKS ──────────────────────────────────────────────
# Azure gère le control plane gratuitement.
# On déclare uniquement les 2 nœuds workers dans le default_node_pool.
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name

  # ---- Nœuds workers (2 × Standard_B2s) ---------------------
  default_node_pool {
    name       = "workers"
    node_count = var.worker_count
    vm_size    = var.node_vm_size
  }

  # ---- Identité managée (pas de service principal à gérer) ---
  identity {
    type = "SystemAssigned"
  }

  # ---- Réseau ------------------------------------------------
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    project    = "gestion-signalement"
    managed_by = "terraform"
  }
}
