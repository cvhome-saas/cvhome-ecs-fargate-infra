locals {
  default_capacity_provider = {
    FARGATE = {
      weight = 50
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
  pods_env = flatten([
    for key, value in var.pods : [
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ID_ID", value : value.id },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_NAME", value : value.name },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ENDPOINT_ENDPOINT", value : value.endpoint },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ENDPOINT_ENDPOINT-TYPE", value : value.endpointType },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ORG-ID", value : value.org },
    ]
  ])
  store_core_gateway_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {
      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },
  ]
  manager_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {
      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },

    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },
    { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-core-db.db_instance_name },
    { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-core-db.db_instance_address },
    { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-core-db.db_instance_port },
    { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-core-db.db_instance_username },
  ]
  manager_secret = [
    {
      name : "SPRING_DATASOURCE_PASSWORD",
      valueFrom = "${module.store-core-db.db_instance_master_user_secret_arn}:password::"
    }
  ]
  subscription_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {
      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },

    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },


    { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-core-db.db_instance_name },
    { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-core-db.db_instance_address },
    { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-core-db.db_instance_port },
    { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-core-db.db_instance_username },
  ]
  subscription_secret = [
    {
      name      = "COM_ASREVO_CVHOME_STRIPE_KEY"
      valueFrom = "${data.aws_secretsmanager_secret.stripe.arn}:STRIPE_KEY::"
    },
    {
      name      = "COM_ASREVO_CVHOME_STRIPE_WEBHOOK"
      valueFrom = "${data.aws_secretsmanager_secret.stripe.arn}:STRIPE_WEBHOOK-SIGNING-KEY::"
    },
    {
      name : "SPRING_DATASOURCE_PASSWORD",
      valueFrom = "${module.store-core-db.db_instance_master_user_secret_arn}:password::"
    }
  ]
  core-auth_env = [
    { "name" : "KC_HTTP_PORT", "value" : "8001" },
    { "name" : "KC_HTTP_ENABLED", "value" : "true" },
    { "name" : "KC_HTTP_MANAGEMENT_PORT", "value" : "9000" },
    { "name" : "KC_HEALTH_ENABLED", "value" : "true" },
    { "name" : "KC_HOSTNAME_STRICT_HTTPS", "value" : "false" },
    { "name" : "KC_DB", "value" : "postgres" },
    { "name" : "KC_DB_URL_DATABASE", "value" : module.store-core-db.db_instance_name },
    { "name" : "KC_DB_URL_HOST", "value" : module.store-core-db.db_instance_address },
    { "name" : "KC_DB_URL_PORT", "value" : module.store-core-db.db_instance_port },
    { "name" : "KC_DB_USERNAME", "value" : module.store-core-db.db_instance_username },
  ]
  core-auth_secret = [
    {
      name      = "KEYCLOAK_ADMIN"
      valueFrom = "${data.aws_secretsmanager_secret.kc.arn}:KEYCLOAK_ADMIN::"
    },
    {
      name      = "KEYCLOAK_ADMIN_PASSWORD"
      valueFrom = "${data.aws_secretsmanager_secret.kc.arn}:KEYCLOAK_ADMIN_PASSWORD::"
    },
    {
      name : "KC_DB_PASSWORD",
      valueFrom = "${module.store-core-db.db_instance_master_user_secret_arn}:password::"
    }

  ]

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
      main_container_port         = 8010
      health_check = {
        path                = "/"
        port                = 8010
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-ui" = {
          image = "${var.docker_registry}/store-core/store-ui:${var.image_tag}"
          environment : []
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8010,
              hostPort : 8010,
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
      main_container_port         = 8011
      health_check = {
        path                = "/"
        port                = 8011
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "welcome-ui" = {
          image = "${var.docker_registry}/store-core/welcome-ui:${var.image_tag}"
          environment : []
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8011,
              hostPort : 8011,
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
          main_container_port            = 8000
        }
      }
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-core-gateway"
      main_container_port         = 8000
      health_check = {
        path                = "/actuator/health"
        port                = 8000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-core-gateway" = {
          image = "${var.docker_registry}/store-core/store-core-gateway:${var.image_tag}"
          environment : concat(local.store_core_gateway_env, local.pods_env)
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8000,
              hostPort : 8000,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "core-auth" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "core-auth-tg" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["core-auth-tg"].arn
          main_container                 = "core-auth"
          main_container_port            = 8001
        }
      }

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "core-auth"
      main_container_port         = 8001
      health_check = {
        path                = "/health"
        port                = 9000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "core-auth" = {
          image = "${var.docker_registry}/store-core/core-auth:${var.image_tag}"
          environment : local.core-auth_env
          secrets : local.core-auth_secret
          portMappings : [
            {
              name : "app",
              containerPort : 8001,
              hostPort : 8001,
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
      main_container_port         = 8020
      health_check = {
        path                = "/actuator/health"
        port                = 8020
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "manager" = {
          image = "${var.docker_registry}/store-core/manager:${var.image_tag}"
          environment : concat(local.manager_env, local.pods_env)
          secrets : local.manager_secret
          portMappings : [
            {
              name : "app",
              containerPort : 8020,
              hostPort : 8020,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "subscription" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "subscription"
      main_container_port         = 8021
      health_check = {
        path                = "/actuator/health"
        port                = 8021
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "subscription" = {
          image = "${var.docker_registry}/store-core/subscription:${var.image_tag}"
          environment : concat(local.subscription_env, local.pods_env)
          secrets : local.subscription_secret
          portMappings : [
            {
              name : "app",
              containerPort : 8021,
              hostPort : 8021,
              protocol : "tcp"
            }
          ]
        }
      }
    }
  }
}


module "store-core-cluster" {
  source                             = "terraform-aws-modules/ecs/aws"
  cluster_name                       = "${local.module_name}-${var.project}-${var.env}"
  default_capacity_provider_strategy = local.default_capacity_provider
  tags                               = var.tags
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

