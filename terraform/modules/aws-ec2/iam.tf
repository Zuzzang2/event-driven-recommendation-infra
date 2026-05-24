# EC2 인스턴스 역할 — k3s 파드(ESO)가 IMDS를 통해 SSM Parameter Store 를 읽기 위함
data "aws_region" "current" {}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "k3s" {
  name               = "${var.project_name}-k3s-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = { Name = "${var.project_name}-k3s-role" }
}

# /<project_name>/* 경로의 SSM 파라미터 읽기 + SecureString 복호화(aws/ssm 키)
data "aws_iam_policy_document" "ssm_read" {
  statement {
    sid       = "SSMParamRead"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:*:*:parameter/${var.project_name}/*"]
  }
  statement {
    sid       = "KmsDecryptViaSSM"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "${var.project_name}-ssm-read"
  role   = aws_iam_role.k3s.id
  policy = data.aws_iam_policy_document.ssm_read.json
}

resource "aws_iam_instance_profile" "k3s" {
  name = "${var.project_name}-k3s-profile"
  role = aws_iam_role.k3s.name
}
