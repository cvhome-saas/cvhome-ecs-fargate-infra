# cluster_sg = {
#
#   alb_ingress_3000 = {
#     type      = "ingress"
#     from_port = 0
#     to_port   = 65535
#     protocol  = "tcp"
#     description = "Service port"
#     # source_security_group_id = module.cluster-lb.security_group_id
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   egress_all = {
#     type      = "egress"
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
# }

#
# resource "aws_security_group" "service-to-service-sg" {
#   name   = "${var.project}-s-to-s-sg-${var.env}"
#   tags   = merge(local.env, { "Name" = "s-to-s-sg" })
#   vpc_id = var.vpc_id
#   ingress {
#     from_port = 0
#     to_port   = 65535
#     protocol  = "tcp"
#     cidr_blocks = [
#       var.cidr_block
#     ]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
# }
#
# resource "aws_security_group" "public-to-service-sg" {
#   name   = "${var.project}-public-to-s-sg-${var.env}"
#   tags   = merge(local.env, { "Name" = "public-to-s-sg" })
#   vpc_id = var.vpc_id
#   ingress {
#     from_port = 0
#     to_port   = 65535
#     protocol  = "tcp"
#     cidr_blocks = [
#       local.public_cidr_block
#     ]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
#

module "service_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project}-${var.module_name}-${var.service_name}-sg-${var.env}"
  description = "Postgres db security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  egress_with_cidr_blocks  = var.egress_with_cidr_blocks

  tags = var.tags
}


resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_name
  desired_count   = var.service.desired
  task_definition = aws_ecs_task_definition.this.family

  network_configuration {
    subnets          = var.subnet
    assign_public_ip = var.service.public
    security_groups  = [module.service_security_group.security_group_id]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.service.main_container
  }
  dynamic "load_balancer" {
    for_each = var.service.loadbalancer_target_groups
    content {
      target_group_arn = load_balancer.value.loadbalancer_target_groups_arn
      container_name   = load_balancer.value.main_container
      container_port   = load_balancer.value.main_container_port
    }
  }

  health_check_grace_period_seconds = 0
  #  launch_type = "FARGATE"
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
  deployment_controller {
    type = "ECS"
  }
  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }
}


# services = {
#   for key, value in local.cluster_services : key => merge(value,
#     {
#       security_group_rules = local.cluster-sg
#       subnet_ids           = var.public_subnets
#       assign_public_ip     = true
#       service_registries = {
#         registry_arn   = aws_service_discovery_service.cluster-service[key].arn
#         container_name = value.container_definitions.app.port_mappings[0].name
#         container_port = value.container_definitions.app.port_mappings[0].containerPort
#       }
#       load_balancer = try(value.loadbalancer_target_groups, null)!=null ? {
#         service = {
#           target_group_arn = module.cluster-lb.target_groups[value.loadbalancer_target_groups].arn
#           container_name   = value.container_definitions.app.port_mappings[0].name
#           container_port   = value.container_definitions.app.port_mappings[0].containerPort
#         }
#       } : {}
#     }
#   )
# }
