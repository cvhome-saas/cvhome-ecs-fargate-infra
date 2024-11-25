# locals {
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       description = "HTTP web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#     all_https = {
#       from_port   = 443
#       to_port     = 443
#       ip_protocol = "tcp"
#       description = "HTTPS web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
#   security_group_egress_rules = {
#     all = {
#       ip_protocol = "-1"
#       cidr_ipv4   = var.vpc_cidr_block
#     }
#   }
# }
# module "cluster-lb" {
#   source = "terraform-aws-modules/alb/aws"
#
#   name                       = "${var.module_name}-${var.project}-${var.env}"
#   vpc_id                     = var.vpc_id
#   subnets                    = var.public_subnets
#   enable_deletion_protection = false
#
#
#
#   access_logs = {
#     bucket = var.log_s3_bucket_id
#     prefix = "${var.module_name}-lb-access-logs"
#   }
#
#   # Security Group
#   security_group_ingress_rules = local.security_group_ingress_rules
#   security_group_egress_rules  = local.security_group_egress_rules
#
#
#   listeners = {
#     ex-http-https-redirect = {
#       port     = 80
#       protocol = "HTTP"
#       redirect = {
#         port        = "443"
#         protocol    = "HTTPS"
#         status_code = "HTTP_301"
#       }
#     }
#     ex-fallabck-response = {
#       port            = 443
#       protocol        = "HTTPS"
#       certificate_arn = var.certificate_arn
#       fixed_response = {
#         content_type = "text/plain"
#         message_body = "ALB not matched any routes"
#         status_code  = "404"
#       }
#       rules = {
#         core-forward = {
#           priority = 1
#           actions = [
#             {
#               type             = "forward"
#               target_group_key = "gateway-tg"
#             }
#           ]
#           conditions = [
#             {
#               host_header = {
#                 values = ["${var.module_name}.${var.domain}"]
#               }
#             }
#           ]
#         }
#       }
#     }
#   }
#
#   target_groups = {
#     gateway-tg = {
#       create_attachment = false
#       name_prefix       = "pod"
#       protocol          = "HTTP"
#       port              = 7100
#       target_type       = "ip"
#
#       health_check = {
#         enabled             = true
#         interval            = 45
#         path                = "/actuator/health"
#         port                = 7100
#         healthy_threshold   = 3
#         unhealthy_threshold = 2
#         timeout             = 5
#         protocol            = "HTTP"
#         matcher             = "200"
#       }
#     }
#   }
#
#   tags = var.tags
# }
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

  name                       = "${var.module_name}-${var.project}-${var.env}"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false

  load_balancer_type = "network"

  # Security Group
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  security_group_ingress_rules                                 = local.security_group_ingress_rules
  security_group_egress_rules                                  = local.security_group_egress_rules

  access_logs = {
    bucket = var.log_s3_bucket_id
    prefix = "${var.module_name}-lb-access-logs"
  }

  listeners = {
    ex-tcp-80 = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "gateway-tg-80"
      }
    }
    ex-tcp-443 = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = "gateway-tg-443"
      }
    }
  }

  target_groups = {
    gateway-tg-80 = {
      create_attachment = false
      name_prefix       = "saas"
      protocol          = "TCP"
      port              = 80
      target_type       = "ip"
      health_check = {
        enabled             = true
        interval            = 45
        path                = "/config/"
        port                = 2019
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    gateway-tg-443 = {
      create_attachment = false
      name_prefix       = "saas"
      protocol          = "TCP"
      port              = 443
      target_type       = "ip"
      health_check = {
        enabled             = true
        interval            = 45
        path                = "/config/"
        port                = 2019
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

module "saas-pod-gateway-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain_zone_name

  records = [
    {
      name = "saas-pod-gateway-${var.index}"
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}

module "wildcard-saas-pod-gateway-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain_zone_name

  records = [
    {
      name = "*.saas-pod-gateway-${var.index}"
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}
