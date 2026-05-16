#!/bin/bash
# ============================================================
# Script de provisioning : 2 VMs Azure pour Kubernetes
# VM1 : master (control plane)
# VM2 : worker (node)
# Usage : bash provision-vms.sh
# Prérequis : az cli installé et connecté (az login)
# ============================================================

set -e

# ---------- Variables à adapter ----------
RESOURCE_GROUP="rg-k8s-signalement"
LOCATION="westeurope"
VNET_NAME="vnet-k8s"
SUBNET_NAME="subnet-k8s"
NSG_NAME="nsg-k8s"
VM_SIZE="Standard_B2s"          # 2 vCPU, 4 GB RAM
IMAGE="Ubuntu2204"
ADMIN_USER="azureuser"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"   # Adapter si nécessaire
# -----------------------------------------

echo "==> Création du groupe de ressources..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "==> Création du réseau virtuel et sous-réseau..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefix "10.0.0.0/16" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefix "10.0.1.0/24"

echo "==> Création du NSG (règles SSH + ports K8s)..."
az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME"

# SSH
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" \
  --name "Allow-SSH" --priority 100 --protocol Tcp --destination-port-ranges 22 --access Allow

# API Server Kubernetes (master)
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" \
  --name "Allow-K8s-API" --priority 110 --protocol Tcp --destination-port-ranges 6443 --access Allow

# NodePort services (30000-32767)
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" \
  --name "Allow-NodePort" --priority 120 --protocol Tcp --destination-port-ranges "30000-32767" --access Allow

# HTTP/HTTPS
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" \
  --name "Allow-HTTP" --priority 130 --protocol Tcp --destination-port-ranges 80 443 --access Allow

echo "==> Création de la VM master (k8s-master)..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "k8s-master" \
  --image "$IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --ssh-key-values "$SSH_KEY_PATH" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --nsg "$NSG_NAME" \
  --public-ip-sku Standard \
  --public-ip-address "pip-k8s-master" \
  --os-disk-size-gb 30

echo "==> Création de la VM worker (k8s-worker1)..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "k8s-worker1" \
  --image "$IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --ssh-key-values "$SSH_KEY_PATH" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --nsg "$NSG_NAME" \
  --public-ip-sku Standard \
  --public-ip-address "pip-k8s-worker1" \
  --os-disk-size-gb 30

echo ""
echo "==> IPs publiques des VMs :"
MASTER_IP=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "k8s-master" \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
WORKER_IP=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "k8s-worker1" \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo "  k8s-master  : $MASTER_IP"
echo "  k8s-worker1 : $WORKER_IP"
echo ""
echo "==> Prochaine étape : exécuter setup-k8s-master.sh sur $MASTER_IP"
echo "    ssh $ADMIN_USER@$MASTER_IP"
