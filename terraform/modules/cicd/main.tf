variable "name" { type = string }
variable "create_oidc_provider" { type = bool }
variable "github_subject" { type = string }
variable "ecr_repository_arn" { type = string }
variable "bastion_security_group_arn" { type = string }

locals {
  issuer       = "token.actions.githubusercontent.com"
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# AWS allows one provider per issuer URL in an account.
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = "https://${local.issuer}"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://${local.issuer}"
}

resource "aws_iam_role" "deploy" {
  name                 = "${var.name}-github-deploy"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = local.provider_arn }
      Condition = {
        StringEquals = {
          "${local.issuer}:aud" = "sts.amazonaws.com"
          "${local.issuer}:sub" = var.github_subject
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "${var.name}-deploy"
  role = aws_iam_role.deploy.id
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
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        # The pipeline opens SSH on the bastion for its own address, then closes it.
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = var.bastion_security_group_arn
      }
    ]
  })
}

output "role_arn" { value = aws_iam_role.deploy.arn }
