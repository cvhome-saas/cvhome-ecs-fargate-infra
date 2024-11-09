module "store-core-lb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "store-core-lb-${var.project}"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false



  access_logs = {
    bucket = var.log_s3_bucket_id
    prefix = "store-core-lb-access-logs"
  }

  # Security Group
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
      cidr_ipv4   = "10.0.0.0/16"
    }
  }


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
    ex-fixed-response = {
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
              target_group_key = "store-core-tg"
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
      port              = 80
      target_type       = "ip"
    }
    store-core-tg = {
      create_attachment = false
      name_prefix       = "core"
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
    }
  }

  tags = local.tags
}
