locals {
  store-core-dns-name = "store-core.${var.project}.lcl"
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
      cpu              = 512
      memory           = 1024
      assign_public_ip = true
      # service_registries = {
      #   registry_arn   = aws_service_discovery_service.this.arn
      #   container_name = "ecs-sample"
      #   container_port = 80
      # }
      container_definitions = {

        ecs-sample = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "nginx"
          port_mappings = [
            {
              name          = "ecs-sample"
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

      load_balancer = {
        service = {
          target_group_arn = module.store-core-lb.target_groups["store-core-tg"].arn
          container_name   = "ecs-sample"
          container_port   = 80
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
}
#
#
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "store-core-${var.project}"

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

  services = local.store-core-cluster-services


  tags = local.tags
}
