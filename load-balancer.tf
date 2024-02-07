data "aws_acm_certificate" "wildcard" {
  domain      = lookup(var.alb_settings, "acm_tls_cert_domain")
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_security_group" "alb" {
  name        = "alb_public_access"
  description = "Public access for load balancer"
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "Allow HTTPS connections from everywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTP connections to allow redirection to HTTPS"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_lb" "public" {
  name               = lookup(var.project_meta, "name")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = lookup(var.alb_settings, "subnets")

  enable_deletion_protection = false
  ip_address_type            = "dualstack"

  idle_timeout = 1800
}

resource "aws_lb_target_group" "main" {
  name            = lookup(var.project_meta, "name")
  port            = lookup(var.container_settings, "app_port")
  protocol        = "HTTP"
  vpc_id          = var.aws_vpc_id
  target_type     = "ip"
  ip_address_type = "ipv4" // Or ipv6

  health_check {
    enabled = true
    path    = lookup(var.alb_settings, "health_check_path")
    port    = "traffic-port"

    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 6
  }
}

resource "aws_lb_listener" "secure" {
  load_balancer_arn = aws_lb.public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = lookup(var.alb_settings, "tls_cipher_policy")
  certificate_arn   = data.aws_acm_certificate.wildcard.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_listener" "insecure" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

