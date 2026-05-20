variable "resource_group_name" {
  description = "Nom du groupe de ressources Azure"
  type        = string
  default     = "rg-aks-signalement"
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "westeurope"
}

variable "cluster_name" {
  description = "Nom du cluster AKS"
  type        = string
  default     = "aks-signalement"
}

variable "worker_count" {
  description = "Nombre de nœuds workers (hors control plane géré par Azure)"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "Taille des VMs pour les nœuds workers"
  type        = string
  default     = "Standard_B2s"
}
