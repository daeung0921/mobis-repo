provider "kubernetes" {
  config_path = "$HOME/.kube/kubeconfig"
  config_context = "kubernetes-admin@kubernetes"
} 