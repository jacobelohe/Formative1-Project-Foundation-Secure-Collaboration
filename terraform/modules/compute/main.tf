data "aws_ssm_parameter" "ubuntu" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "operator" {
  key_name   = var.name
  public_key = var.ssh_public_key
}

locals {
  extra_keys = length(var.additional_ssh_public_keys) == 0 ? null : join("\n", [
    "#cloud-config",
    yamlencode({ ssh_authorized_keys = distinct(var.additional_ssh_public_keys) }),
  ])
  ami = var.ami_id == null ? data.aws_ssm_parameter.ubuntu[0].insecure_value : var.ami_id
}

resource "aws_instance" "app" {
  ami                         = local.ami
  instance_type               = var.app_instance_type
  subnet_id                   = var.app_subnet_id
  vpc_security_group_ids      = [var.app_security_group_id]
  key_name                    = aws_key_pair.operator.key_name
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false
  user_data                   = local.extra_keys
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 16
  }

  tags = { Name = "${var.name}-app" }
}

resource "aws_iam_role" "app" {
  name = "${var.name}-app-ecr-pull"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.name}-ecr-pull"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app"
  role = aws_iam_role.app.name
}

resource "aws_instance" "bastion" {
  ami                         = local.ami
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = true
  user_data                   = local.extra_keys
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = { Name = "${var.name}-bastion" }
}

output "instance_id" { value = aws_instance.app.id }
output "private_ip" { value = aws_instance.app.private_ip }
output "bastion_id" { value = aws_instance.bastion.id }
output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
