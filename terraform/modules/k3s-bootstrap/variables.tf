variable "public_ip" {
  type = string
}

variable "ssh_private_key_path" {
  type        = string
  description = "로컬 SSH 개인키 경로 (예: ~/.ssh/id_rsa)"
}

variable "kubeconfig_local_path" {
  type    = string
  default = "~/.kube/k3s-config"
}
