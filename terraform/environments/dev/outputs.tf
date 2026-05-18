output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "kubeconfig_path" {
  value = module.k3s.kubeconfig_path
}
