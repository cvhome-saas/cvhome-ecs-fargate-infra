data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.project}/${var.env}/${var.module_name}/${var.service_name}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "this" {
  cpu                      = var.service.cpu
  memory                   = var.service.memory
  family                   = "${var.project}-${var.service_name}-${var.env}"
  network_mode             = "awsvpc"
  requires_compatibilities = var.requires_compatibilities
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    for it in keys(var.service.containers) : {
      name : it
      image : var.service.containers[it].image
      portMappings : var.service.containers[it].portMappings
      cpu : 0,
      user : "root",
      essential : true,
      environment : var.service.containers[it].environment,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.this.name,
          awslogs-region : data.aws_region.current.name,
          awslogs-stream-prefix : "ecs-${var.service_name}-${it}"
        }
      }
    }
  ])
  tags = var.tags
}