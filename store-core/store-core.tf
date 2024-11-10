locals {
  module-name = "store-core"
  tags = var.tags
  store-core-env=[
    {"name":"SPRING_PROFILES_ACTIVE","value":"fargate"},
    {"name":"COM_ASREVO_CVHOME_APP_DOMAIN","value":var.domain},
    {"name":"COM_ASREVO_CVHOME_SERVICES_CORE-GATEWAY_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_CORE-GATEWAY_PORT","value":"443"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT","value":"443"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_AUTH_PORT","value":"443"},
    {"name":"SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE","value":local.cluster-dnsname},
    {"name":"SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID","value":aws_service_discovery_private_dns_namespace.cluster-namespace.id},
  ]
  manager-env=[
    {"name":"SPRING_PROFILES_ACTIVE","value":"fargate"},
    {"name":"COM_ASREVO_CVHOME_APP_DOMAIN","value":var.domain},
    {"name":"COM_ASREVO_CVHOME_SERVICES_CORE-GATEWAY_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_CORE-GATEWAY_PORT","value":"443"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT","value":"443"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_AUTH_SCHEMA","value":"https"},
    {"name":"COM_ASREVO_CVHOME_SERVICES_AUTH_PORT","value":"443"},
    {"name":"SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE","value":local.cluster-dnsname},
    {"name":"SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID","value":aws_service_discovery_private_dns_namespace.cluster-namespace.id},

    {"name":"COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE","value":"store-pod-1.cvhome.lcl"},
    {"name":"SPRING_DATASOURCE_DATABASE","value":module.db.db_instance_name},
    {"name":"SPRING_DATASOURCE_HOST","value":module.db.db_instance_address},
    {"name":"SPRING_DATASOURCE_PORT","value":module.db.db_instance_port},
    {"name":"SPRING_DATASOURCE_USERNAME","value":module.db.db_instance_username},
    {"name":"SPRING_DATASOURCE_PASSWORD","value":nonsensitive(local.db-password)},
  ]
  auth-env=[
    {"name":"KC_HTTP_PORT","value":"9999"},
    {"name":"KC_HTTP_ENABLED","value":"true"},
    {"name":"KC_HOSTNAME_STRICT_HTTPS","value":"false"},
    {"name":"KEYCLOAK_ADMIN","value":"sys-admin@mail.com"},
    {"name":"KEYCLOAK_ADMIN_PASSWORD","value":"admin"},


    {"name":"KC_DB","value":"postgres"},
    {"name":"KC_DB_URL_DATABASE","value":module.db.db_instance_name},
    {"name":"KC_DB_URL_HOST","value":module.db.db_instance_address},
    {"name":"KC_DB_URL_PORT","value":module.db.db_instance_port},
    {"name":"KC_DB_USERNAME","value":module.db.db_instance_username},
    {"name":"KC_DB_PASSWORD","value":nonsensitive(local.db-password)},
  ]
  cluster-services = {
    store-ui = {
      cpu    = 512
      memory = 1024
      container_definitions = {
        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/b2i4h4k9/store-core/store-ui:0.0.1"
          port_mappings = [
            {
              name          = local.default_container_name
              containerPort = 4200
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem  = false
          dependencies = []
          enable_cloudwatch_logging = true
          memory_reservation        = 100
        }
      }
    }
    welcome-ui = {
      cpu    = 512
      memory = 1024
      container_definitions = {
        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/b2i4h4k9/store-core/welcome-ui:0.0.1"
          port_mappings = [
            {
              name          = local.default_container_name
              containerPort = 4300
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem  = false
          dependencies = []
          enable_cloudwatch_logging = true
          memory_reservation        = 100
        }
      }
    }
    store-core-gateway = {
      loadbalancer_target_groups = "gateway-tg"
      cpu                        = 512
      memory                     = 1024
      container_definitions = {
        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/b2i4h4k9/store-core/store-core-gateway:0.0.1"
          port_mappings = [
            {
              name          = local.default_container_name
              containerPort = 7000
              protocol      = "tcp"
            }
          ]
          # Example image used requires access to write to root filesystem
          readonly_root_filesystem  = false
          dependencies = []
          enable_cloudwatch_logging = true
          memory_reservation        = 100
        }
      }
    }
    auth = {
      loadbalancer_target_groups = "auth-tg"
      cpu                        = 512
      memory                     = 1024
      container_definitions = {
        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/b2i4h4k9/store-core/auth:0.0.1"
          port_mappings = [
            {
              name          = local.default_container_name
              containerPort = 9999
              protocol      = "tcp"
            }
          ]
          # Example image used requires access to write to root filesystem
          readonly_root_filesystem  = false
          dependencies = []
          enable_cloudwatch_logging = true
          memory_reservation        = 100
        }
      }
    }
  }
}
