locals {
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
  services = {
    "saas-pod-gateway" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {
        "gateway-tg-80" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg-80"].arn
          main_container                 = "saas-pod-gateway"
          main_container_port            = 80
        }
        "gateway-tg-443" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg-443"].arn
          main_container                 = "saas-pod-gateway"
          main_container_port            = 443
        }
      }



      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "saas-pod-gateway"
      main_container_port         = 443
      health_check = {
        path                = "/"
        port                = 80
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "saas-pod-gateway" = {
          image = "public.ecr.aws/b2i4h4k9/saas-pod/saas-pod-gateway-v2:0.1.0"
          environment : [
            { "name" : "STORE_POD_GATEWAY", "value" : "http://store-pod-gateway.store-pod-1.cvhome.lcl:7100" },
            {
              "name" : "ASK_TLS_URL",
              "value" : "http://store-core-gateway.store-core.cvhome.lcl:7000/manager/api/v1/router/public/ask-for-tls"
            }
          ]
          portMappings : [
            {
              name : "app443",
              containerPort : 443,
              hostPort : 443,
              protocol : "tcp"
            },
            {
              name : "app80",
              containerPort : 80,
              hostPort : 80,
              protocol : "tcp"
            }
          ]
        }
      }
    }
  }
}


module "saas-pod-cluster" {
  source                     = "terraform-aws-modules/ecs/aws"
  cluster_name               = "${local.module_name}-${var.project}-${var.env}"
  fargate_capacity_providers = local.fargate_capacity_providers
  tags                       = var.tags
}

module "saas-pod-service" {
  source       = "../common/ecs-service"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.saas-pod-cluster.cluster_name
  env          = var.env
  module_name  = local.module_name
  project      = var.project
  service      = each.value
  subnet       = var.public_subnets
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow ingress traffic access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow egress traffic access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  for_each = local.services
  vpc_id   = var.vpc_id
}

