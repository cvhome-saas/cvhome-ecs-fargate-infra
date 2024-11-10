locals {
  module-name = "store-core"
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
  }
  tags = var.tags
}