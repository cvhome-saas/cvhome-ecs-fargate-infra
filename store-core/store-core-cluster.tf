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
    "store-ui" = {
      public                      = true
      priority                    = 100
      service_type                = "SERVICE"
      loadbalancer_target_groups  = {}
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-ui"
      main_container_port         = 4200
      health_check = {
        path                = "/"
        port                = 4200
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-ui" = {
          image = "public.ecr.aws/b2i4h4k9/store-core/store-ui:0.1.0"
          environment : []
          portMappings : [
            {
              name : "app",
              containerPort : 4200,
              hostPort : 4200,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "welcome-ui" = {
      public                      = true
      priority                    = 100
      service_type                = "SERVICE"
      loadbalancer_target_groups  = {}
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "welcome-ui"
      main_container_port         = 4300
      health_check = {
        path                = "/"
        port                = 4300
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "welcome-ui" = {
          image = "public.ecr.aws/b2i4h4k9/store-core/welcome-ui:0.1.0"
          environment : []
          portMappings : [
            {
              name : "app",
              containerPort : 4300,
              hostPort : 4300,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store-core-gateway" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "gateway-tg" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg"].arn
          main_container                 = "store-core-gateway"
          main_container_port            = 7000
        }
      }
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-core-gateway"
      main_container_port         = 7000
      health_check = {
        path                = "/actuator/health"
        port                = 7000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-core-gateway" = {
          image = "public.ecr.aws/b2i4h4k9/store-core/store-core-gateway:0.1.0"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : local.cluster_dnsname },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 7000,
              hostPort : 7000,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "auth" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "auth-tg" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["auth-tg"].arn
          main_container                 = "auth"
          main_container_port            = 9999
        }
      }

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "auth"
      main_container_port         = 9999
      health_check = {
        path                = "/health"
        port                = 9000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "auth" = {
          image = "public.ecr.aws/b2i4h4k9/store-core/auth:0.1.0"
          environment : [
            { "name" : "KC_HTTP_PORT", "value" : "9999" },
            { "name" : "KC_HTTP_ENABLED", "value" : "true" },
            { "name" : "KC_HTTP_MANAGEMENT_PORT", "value" : "9000" },
            { "name" : "KC_HEALTH_ENABLED", "value" : "true" },
            { "name" : "KC_HOSTNAME_STRICT_HTTPS", "value" : "false" },
            { "name" : "KEYCLOAK_ADMIN", "value" : "sys-admin@mail.com" },
            { "name" : "KEYCLOAK_ADMIN_PASSWORD", "value" : "admin" },
            { "name" : "KC_DB", "value" : "postgres" },
            { "name" : "KC_DB_URL_DATABASE", "value" : module.store-core-db.db_instance_name },
            { "name" : "KC_DB_URL_HOST", "value" : module.store-core-db.db_instance_address },
            { "name" : "KC_DB_URL_PORT", "value" : module.store-core-db.db_instance_port },
            { "name" : "KC_DB_USERNAME", "value" : module.store-core-db.db_instance_username },
            {
              "name" : "KC_DB_PASSWORD",
              "value" : jsondecode(data.aws_secretsmanager_secret_version.current_db_secret_version.secret_string)["password"]
            },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 9999,
              hostPort : 9999,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "manager" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "manager"
      main_container_port         = 7001
      health_check = {
        path                = "/actuator/health"
        port                = 7001
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "manager" = {
          image = "public.ecr.aws/b2i4h4k9/store-core/manager:0.1.0"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : local.cluster_dnsname },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },

            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.cvhome.lcl" },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-core-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-core-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-core-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-core-db.db_instance_username },
            {
              "name" : "SPRING_DATASOURCE_PASSWORD",
              "value" : jsondecode(data.aws_secretsmanager_secret_version.current_db_secret_version.secret_string)["password"]
            },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 7001,
              hostPort : 7001,
              protocol : "tcp"
            }
          ]
        }
      }
    }
  }
}


module "store-core-cluster" {
  source                     = "terraform-aws-modules/ecs/aws"
  cluster_name               = "${local.module_name}-${var.project}-${var.env}"
  fargate_capacity_providers = local.fargate_capacity_providers
  tags                       = var.tags
}

module "store-core-service" {
  source       = "../common/ecs-service"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.store-core-cluster.cluster_name
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

