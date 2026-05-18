variable "project_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "public_key_path" {
  type        = string
  description = "로컬 SSH 공개키 경로"
}

variable "spot_max_price" {
  type    = string
  default = "0.05"
}
