data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "k3s" {
  ami           = data.aws_ami.ubuntu_arm.id
  instance_type = "t4g.large"
  subnet_id     = var.subnet_id
  key_name      = aws_key_pair.this.key_name

  vpc_security_group_ids = [var.sg_id]

  # ESO 등 파드가 IMDS로 인스턴스 역할 자격증명을 받아 SSM 접근
  iam_instance_profile = aws_iam_instance_profile.k3s.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 강제
    http_put_response_hop_limit = 2          # 파드(추가 1홉)에서 IMDS 접근 허용
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.spot_max_price
    }
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-k3s" }
}

resource "aws_eip" "k3s" {
  instance = aws_instance.k3s.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-eip" }
}
