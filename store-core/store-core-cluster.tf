locals {
  default_container_name = "app"
  cluster-sg = {

    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Service port"
      # source_security_group_id = module.cluster-lb.security_group_id
      cidr_blocks = ["0.0.0.0/0"]
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


module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.module_name}-${var.project}-${var.env}"

  fargate_capacity_providers = local.fargate_capacity_providers

  services = {
    for key, value in local.cluster_services : key => merge(value,
      {
        security_group_rules = local.cluster-sg
        subnet_ids           = var.public_subnets
        assign_public_ip     = true
        service_registries = {
          registry_arn   = module.resource.service_discovery_service_arn[key].arn
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


  tags = var.tags
  depends_on = [module.resource.service_discovery_service_arn]
}
