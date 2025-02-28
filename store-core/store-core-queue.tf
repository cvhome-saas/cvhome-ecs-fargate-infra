terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.88.0"
    }
  }
}

resource "aws_secretsmanager_secret" "mq_secret" {
  name = "${local.module_name}-${var.project}-${var.env}-mq"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mq_secret_version" {
  secret_id = aws_secretsmanager_secret.mq_secret.id
  secret_string = jsonencode({
    "username" : "admin"
    "password" : random_password.password.result
  })
}

resource "aws_mq_broker" "mq" {
  broker_name         = "${local.module_name}-${var.project}-${var.env}"
  engine_type         = "RabbitMQ"
  engine_version      = "3.11.28"
  host_instance_type  = "mq.t3.micro"
  deployment_mode     = "SINGLE_INSTANCE"
  subnet_ids          = [var.public_subnets[0]]
  publicly_accessible = true
  configuration {
    id       = aws_mq_configuration.mq_config.id
    revision = aws_mq_configuration.mq_config.latest_revision
  }

  user {
    username = jsondecode(aws_secretsmanager_secret_version.mq_secret_version.secret_string)["username"]
    password = jsondecode(aws_secretsmanager_secret_version.mq_secret_version.secret_string)["password"]
  }

  apply_immediately = true
}


resource "aws_mq_configuration" "mq_config" {
  description    = "RabbitMQ config"
  name           = "rabbitmq-broker"
  engine_type    = "RabbitMQ"
  engine_version = "3.13"
  data           = <<DATA
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes in milliseconds
consumer_timeout = 1800000
DATA
}