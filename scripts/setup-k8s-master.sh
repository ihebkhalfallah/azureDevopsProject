#!/bin/bash
# ============================================================
# Script d'installation Kubernetes - MASTER (control plane)
# À exécuter sur la VM k8s-master en SSH
# Usage : bash setup-k8s-master.sh
# ============================================================

set -e

echo "===== [1/6] Désactivation du swap ====="
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "===== [2/6] Chargement des modules kernel ====="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

echo "===== [3/6] Installation de containerd ====="
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y containerd.io

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "===== [4/6] Installation de kubeadm, kubelet, kubectl ====="
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

echo "===== [5/6] Initialisation du cluster (kubeadm init) ====="
MASTER_IP=$(hostname -I | awk '{print $1}')
kubeadm init \
  --apiserver-advertise-address="$MASTER_IP" \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock

echo "===== [6/6] Configuration kubectl pour l'utilisateur courant ====="
mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "===== Installation du réseau Calico ====="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo ""
echo "===== CLUSTER PRÊT ====="
echo "Copiez la commande 'kubeadm join' ci-dessous et exécutez-la sur le worker :"
echo ""
kubeadm token create --print-join-command
echo ""
echo "Pour récupérer le kubeconfig depuis votre machine locale :"
echo "  scp azureuser@${MASTER_IP}:~/.kube/config ./kubeconfig-k8s"
