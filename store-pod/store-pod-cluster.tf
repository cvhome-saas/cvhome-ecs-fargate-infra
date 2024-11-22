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
    "landing-ui" = {
      public                      = true
      priority                    = 100
      service_type                = "SERVICE"
      loadbalancer_target_groups  = {}
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "landing-ui"
      main_container_port         = 7102
      health_check = {
        path                = "/"
        port                = 7102
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "landing-ui" = {
          image = "${var.docker_registry}/store-pod/landing-ui:${var.image_tag}"
          environment : []
          portMappings : [
            {
              name : "app",
              containerPort : 7102,
              hostPort : 7102,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store"
      main_container_port         = 7101
      health_check = {
        path                = "/actuator/health"
        port                = 7101
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store" = {
          image = "${var.docker_registry}/store-pod/store:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_PROVIDER", "value" : "S3" },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_BUCKET", "value" : module.cdn-storage-bucket.s3_bucket_id },
            {
              "name" : "COM_ASREVO_CVHOME_CDN_BASE-PATH",
              "value" : "https://${module.cdn-storage-cloudfront.cloudfront_distribution_domain_name}"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-pod-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-pod-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-pod-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-pod-db.db_instance_username },
            {
              "name" : "SPRING_DATASOURCE_PASSWORD",
              "value" : jsondecode(data.aws_secretsmanager_secret_version.current_db_secret_version.secret_string)["password"]
            },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 7101,
              hostPort : 7101,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store-pod-gateway" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      # loadbalancer_target_groups = {
      #   "gateway-tg" : {
      #     loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg"].arn
      #     main_container                 = "store-pod-gateway"
      #     main_container_port            = 7100
      #   }
      # }

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-pod-gateway"
      main_container_port         = 7100
      health_check = {
        path                = "/actuator/health"
        port                = 7100
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-pod-gateway" = {
          image = "${var.docker_registry}/store-pod/store-pod-gateway:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MANAGER_NAMESPACE", "value" : "store-core.${var.project}.lcl" },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 7100,
              hostPort : 7100,
              protocol : "tcp"
            }
          ]
        }
      }
    }
  }
}


module "store-pod-cluster" {
  source                     = "terraform-aws-modules/ecs/aws"
  cluster_name               = "${local.module_name}-${var.project}-${var.env}"
  fargate_capacity_providers = local.fargate_capacity_providers
  cluster_settings           = []
  tags                       = var.tags
}

module "store-pod-service" {
  source       = "../common/ecs-service"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.store-pod-cluster.cluster_name
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

