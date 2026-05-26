variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "edr"
}

variable "availability_zone" {
  type    = string
  default = "ap-northeast-2a"
}

variable "public_key_path" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "spot_max_price" {
  type    = string
  default = "0.05"
}

variable "kubeconfig_local_path" {
  type    = string
  default = "~/.kube/k3s-config"
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "SG 인바운드 허용 CIDR (SSH/HTTP/HTTPS/k3s API). tfvars로 내 IP/32 지정 권장"
  default     = ["0.0.0.0/0"]
}
