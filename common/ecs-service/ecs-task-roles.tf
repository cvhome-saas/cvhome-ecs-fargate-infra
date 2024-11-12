resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.module_name}-${var.service_name}-execution-role-${var.env}"
  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid : "sid0"
        Effect : "Allow"
        Principal : {
          Service : [
            "ecs-tasks.amazonaws.com"
          ]
        }
        Action : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${var.project}-${var.module_name}-${var.service_name}-execution-role-policy-${var.env}"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid : "sid0"
        Effect : "Allow"
        Action : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:*"
        ]
        Resource : [
          "*"
        ]
      }
    ]
  })
}


resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.module_name}-${var.service_name}-task-role-${var.env}"
  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid : "sid0"
        Effect : "Allow"
        Principal : {
          Service : [
            "ecs-tasks.amazonaws.com"
          ]
        }
        Action : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.project}-${var.module_name}-${var.service_name}-role-policy-${var.env}"
  role   = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid : "sid0"
        Effect : "Allow"
        Action : [
          "cloudwatch:PutMetricData",
          "servicediscovery:*",
          "s3:*",
          "ssm:*",
          "rds-db:connect",
          "secretsmanager:*"
        ]
        Resource : [
          "*"
        ]
      }
    ]
  })
}
