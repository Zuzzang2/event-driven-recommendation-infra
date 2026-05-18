provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "../../modules/aws-vpc"
  project_name = var.project_name
  az           = var.availability_zone
}

module "sg" {
  source       = "../../modules/aws-sg"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "ec2" {
  source          = "../../modules/aws-ec2"
  project_name    = var.project_name
  subnet_id       = module.vpc.subnet_id
  sg_id           = module.sg.sg_id
  public_key_path = var.public_key_path
  spot_max_price  = var.spot_max_price
}

module "k3s" {
  source                = "../../modules/k3s-bootstrap"
  public_ip             = module.ec2.public_ip
  ssh_private_key_path  = var.ssh_private_key_path
  kubeconfig_local_path = var.kubeconfig_local_path
}
