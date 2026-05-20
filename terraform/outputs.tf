output "cluster_name" {
  description = "Nom du cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  description = "Nom du groupe de ressources"
  value       = azurerm_resource_group.main.name
}

output "kube_config" {
  description = "Contenu brut du kubeconfig (sensible)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
