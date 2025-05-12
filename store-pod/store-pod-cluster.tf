locals {
  profiles = join(",", compact(["fargate", var.test_stores ? "test-stores" : ""]))
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
      public              = true
      priority            = 100
      service_type        = "SERVICE"
      loadbalancer_target_groups = {}
      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "landing-ui"
      main_container_port = 8110
      health_check = {
        path                = "/"
        port                = 8110
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "landing-ui" = {
          image = "${var.docker_registry}/${var.project}/store-pod/landing-ui:${var.image_tag}"
          environment : [
            { "name" : "INTERNAL_STORE_POD_GATEWAY", "value" : "http://store-pod-gateway.${var.pod.endpoint}:8100" }
            # { "name" : "EXTERNAL_STORE_POD_GATEWAY", "value" : "http://store-pod-gateway.${var.pod.endpoint}:8100" }
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8110,
              hostPort : 8110,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "merchant-ui" = {
      public              = true
      priority            = 100
      service_type        = "SERVICE"
      loadbalancer_target_groups = {}
      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "merchant-ui"
      main_container_port = 8111
      health_check = {
        path                = "/"
        port                = 8111
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "merchant-ui" = {
          image = "${var.docker_registry}/${var.project}/store-pod/merchant-ui:${var.image_tag}"
          environment : [
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8111,
              hostPort : 8111,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "merchant" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "merchant"
      main_container_port = 8120
      health_check = {
        path                = "/actuator/health"
        port                = 8120
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "merchant" = {
          image = "${var.docker_registry}/${var.project}/store-pod/merchant:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.endpoint },
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
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.endpoint },
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
              containerPort : 8120,
              hostPort : 8120,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "content" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "content"
      main_container_port = 8121
      health_check = {
        path                = "/actuator/health"
        port                = 8121
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "content" = {
          image = "${var.docker_registry}/${var.project}/store-pod/content:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.endpoint },
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
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.endpoint },
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
              containerPort : 8121,
              hostPort : 8121,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "catalog" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "catalog"
      main_container_port = 8122
      health_check = {
        path                = "/actuator/health"
        port                = 8122
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "catalog" = {
          image = "${var.docker_registry}/${var.project}/store-pod/catalog:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.endpoint },
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
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.endpoint },
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
              containerPort : 8122,
              hostPort : 8122,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "order" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "order"
      main_container_port = 8123
      health_check = {
        path                = "/actuator/health"
        port                = 8123
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "order" = {
          image = "${var.docker_registry}/${var.project}/store-pod/order:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.endpoint },
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
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.endpoint },
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
              containerPort : 8123,
              hostPort : 8123,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store-pod-gateway" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {}

      # loadbalancer_target_groups = {
      #   "gateway-tg" : {
      #     loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg"].arn
      #     main_container                 = "store-pod-gateway"
      #     main_container_port            = 8100
      #   }
      # }

      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "store-pod-gateway"
      main_container_port = 8100
      health_check = {
        path                = "/actuator/health"
        port                = 8100
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-pod-gateway" = {
          image = "${var.docker_registry}/${var.project}/store-pod/store-pod-gateway:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            {
              "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_NAMESPACE",
              "value" : "store-core.${var.project}.lcl"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.endpoint },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8100,
              hostPort : 8100,
              protocol : "tcp"
            }
          ]
        }
      }
    },
    "store-pod-saas-gateway" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "gateway-tg-80" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg-80"].arn
          main_container                 = "store-pod-saas-gateway"
          main_container_port            = 80
        }
        "gateway-tg-443" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg-443"].arn
          main_container                 = "store-pod-saas-gateway"
          main_container_port            = 443
        }
      }



      load_balancer_host_matchers = []
      desired             = 1
      cpu                 = 512
      memory              = 1024
      main_container      = "store-pod-saas-gateway"
      main_container_port = 443
      health_check = {
        path                = "/"
        port                = 80
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-pod-saas-gateway" = {
          image = "${var.docker_registry}/${var.project}/store-pod/store-pod-saas-gateway:${var.image_tag}"
          environment : [
            { "name" : "STORE_POD_GATEWAY", "value" : "http://store-pod-gateway.${var.pod.endpoint}:8100" },
            {
              "name" : "ASK_TLS_URL",
              "value" : "http://store-core-gateway.${var.store_core_namespace}:8000/manager/api/v1/router/public/ask-for-tls"
            },
            {
              "name" : "DOMAIN_LOOKUP_URL",
              "value" : "http://store-core-gateway.${var.store_core_namespace}:8000/manager/api/v1/router/public/lookup-by-domain"
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
            },
            {
              name : "app2019",
              containerPort : 2019,
              hostPort : 2019,
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
  cluster_name               = "${local.module_name}-${var.pod.id}-${var.env}"
  fargate_capacity_providers = local.fargate_capacity_providers
  cluster_settings = []
  tags                       = var.tags
}

module "store-pod-service" {
  source       = "../common/ecs-service"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.store-pod-cluster.cluster_name
  env          = var.env
  module_name  = var.pod.id
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

