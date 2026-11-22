variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "additional_ssh_public_keys" {
  type    = list(string)
  default = []
}

data "aws_ssm_parameter" "ubuntu" {
  count = var.ami_id == null ? 1 : 0

  name = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "operator" {
  key_name   = var.name
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  ami                         = var.ami_id == null ? data.aws_ssm_parameter.ubuntu[0].insecure_value : var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = true
  user_data = length(var.additional_ssh_public_keys) == 0 ? null : join("\n", [
    "#cloud-config",
    yamlencode({ ssh_authorized_keys = distinct(var.additional_ssh_public_keys) }),
  ])
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 16
  }

  tags = { Name = var.name }
}

output "instance_id" {
  value = aws_instance.app.id
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "private_ip" {
  value = aws_instance.app.private_ip
}
