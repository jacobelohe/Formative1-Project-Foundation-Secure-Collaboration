variable "name" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "security_group_id" { type = string }
variable "instance_id" { type = string }
variable "app_port" { type = number }

resource "aws_lb" "app" {
  name                       = substr("${var.name}-web", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  tags                       = { Name = "${var.name}-web" }
}

resource "aws_lb_target_group" "app" {
  name        = substr("${var.name}-app", 0, 32)
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/ready"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "${var.name}-app" }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.instance_id
  port             = var.app_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "url" { value = "http://${aws_lb.app.dns_name}" }
output "dns_name" { value = aws_lb.app.dns_name }
output "arn" { value = aws_lb.app.arn }
