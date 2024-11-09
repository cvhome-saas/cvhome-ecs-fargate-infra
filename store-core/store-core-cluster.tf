locals {
  store-core-dns-name = "${local.module-name}.${var.project}.lcl"
  store-core-cluster-sg = {

    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.store-core-lb.security_group_id
    }

    egress_all = {
      type      = "egress"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }
  store-core-cluster-services = {
    ecsdemo-frontend = {
      loadbalanced               = true
      loadbalancer_target_groups = "store-core-tg"

      cpu              = 512
      memory           = 1024
      assign_public_ip = true
      container_definitions = {

        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "nginx"
          port_mappings = [
            {
              name          = "app"
              containerPort = 80
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false

          dependencies = []

          enable_cloudwatch_logging = false
          memory_reservation        = 100
        }
      }
      subnet_ids           = var.public_subnets
      security_group_rules = local.store-core-cluster-sg
    }
  }
}
resource "aws_service_discovery_private_dns_namespace" "store-core-namespace" {
  name = local.store-core-dns-name
  vpc  = var.vpc_id
  tags = local.tags
}

resource "aws_service_discovery_service" "store-core-service" {
  name = each.key
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.store-core-namespace.id
    dns_records {
      ttl  = 10
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  for_each = local.store-core-cluster-services
  tags     = local.tags
}


module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.module-name}-${var.project}"

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
    for key, value in local.store-core-cluster-services : key => merge(value,
      {
        service_registries = {
          registry_arn   = aws_service_discovery_service.store-core-service[key].arn
          container_name = value.container_definitions.app.port_mappings[0].name
          container_port = value.container_definitions.app.port_mappings[0].containerPort
        }
        load_balancer = value.loadbalanced ? {
          service = {
            target_group_arn = module.store-core-lb.target_groups[value.loadbalancer_target_groups].arn
            container_name   = "app"
            container_port   = 80
          }
        } : null
      }
    )
  }


  tags = local.tags
}
