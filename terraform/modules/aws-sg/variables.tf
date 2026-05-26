variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "인바운드 허용 CIDR (SSH/HTTP/HTTPS/k3s API). 기본 전체 개방, tfvars로 내 IP 제한 권장"
  default     = ["0.0.0.0/0"]
}
