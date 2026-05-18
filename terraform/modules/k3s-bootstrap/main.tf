resource "null_resource" "k3s_install" {
  triggers = {
    public_ip = var.public_ip
  }

  connection {
    type        = "ssh"
    host        = var.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -q",
      # --tls-san으로 공인 IP를 SAN에 등록해 원격 kubectl 접속 허용
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --tls-san ${var.public_ip}' sh -s - --write-kubeconfig-mode 644",
      "until kubectl get nodes 2>/dev/null | grep -q ' Ready'; do sleep 5; done",
      "echo 'k3s ready'"
    ]
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.k3s_install]

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p $(dirname ${var.kubeconfig_local_path})
      scp -o StrictHostKeyChecking=no \
          -i ${var.ssh_private_key_path} \
          ubuntu@${var.public_ip}:/etc/rancher/k3s/k3s.yaml \
          ${var.kubeconfig_local_path}
      python3 -c "
f = open('${var.kubeconfig_local_path}', 'r')
content = f.read()
f.close()
f = open('${var.kubeconfig_local_path}', 'w')
f.write(content.replace('127.0.0.1', '${var.public_ip}'))
f.close()
print('kubeconfig updated: ${var.kubeconfig_local_path}')
"
    EOT
  }
}
