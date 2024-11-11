locals {
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
    }
  }
}
module "cluster-lb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.module_name}-${var.project}-${var.env}"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false



  access_logs = {
    bucket = var.log_s3_bucket_id
    prefix = "${local.module_name}-lb-access-logs"
  }

  # Security Group
  security_group_ingress_rules = local.security_group_ingress_rules
  security_group_egress_rules  = local.security_group_egress_rules


  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-fallabck-response = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "ALB not matched any routes"
        status_code  = "404"
      }
      rules = {
        auth-forward = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "auth-tg"
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["auth.${var.domain}"]
              }
            }
          ]
        }
        core-forward = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-tg"
            }
          ]
          conditions = [
            {
              host_header = {
                values = [var.domain, "www.${var.domain}", "store-ui.${var.domain}"]
              }
            }
          ]
        }
      }
    }
  }

  target_groups = {
    auth-tg = {
      create_attachment = false
      name_prefix       = "auth"
      protocol          = "HTTP"
      port              = 9999
      target_type       = "ip"

      health_check = {
        enabled             = true
        interval            = 150
        path                = "/health"
        port                = 9000
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    gateway-tg = {
      create_attachment = false
      name_prefix       = "core"
      protocol          = "HTTP"
      port              = 7000
      target_type       = "ip"

      health_check = {
        enabled             = true
        interval            = 45
        path                = "/actuator/health"
        port                = 7000
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  tags = var.tags
}
