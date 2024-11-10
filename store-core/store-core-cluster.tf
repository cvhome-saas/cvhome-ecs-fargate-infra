locals {
  cluster-dnsname        = "${local.module-name}.${var.project}.lcl"
  default_container_name = "app"
  cluster-sg = {

    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.cluster-lb.security_group_id
    }

    egress_all = {
      type      = "egress"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }
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
}
resource "aws_service_discovery_private_dns_namespace" "cluster-namespace" {
  name = local.cluster-dnsname
  vpc  = var.vpc_id
  tags = local.tags
}

resource "aws_service_discovery_service" "cluster-service" {
  name = each.key
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cluster-namespace.id
    dns_records {
      ttl  = 10
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  for_each = local.cluster-services
  tags     = local.tags
}


module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.module-name}-${var.project}-${var.env}"

  fargate_capacity_providers = local.fargate_capacity_providers

  services = {
    for key, value in local.cluster-services : key => merge(value,
      {
        security_group_rules = local.cluster-sg
        subnet_ids           = var.public_subnets
        assign_public_ip     = true
        service_registries = {
          registry_arn   = aws_service_discovery_service.cluster-service[key].arn
          container_name = value.container_definitions.app.port_mappings[0].name
          container_port = value.container_definitions.app.port_mappings[0].containerPort
        }
        load_balancer = try(value.loadbalancer_target_groups, null)!=null ? {
          service = {
            target_group_arn = module.cluster-lb.target_groups[value.loadbalancer_target_groups].arn
            container_name   = value.container_definitions.app.port_mappings[0].name
            container_port   = value.container_definitions.app.port_mappings[0].containerPort
          }
        } : {}
      }
    )
  }


  tags = local.tags
}
