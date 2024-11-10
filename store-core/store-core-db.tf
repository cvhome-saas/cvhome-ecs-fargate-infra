module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "db-${local.module-name}-${var.project}-${var.env}"
  description = "Postgres db security group"
  vpc_id = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Db access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]

  tags = local.tags
}


module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.module-name}-${var.project}-${var.env}"

  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = var.db-instance_class
  allocated_storage = var.db-allocated_storage
  family            = "postgres16"


  db_name  = "postgres"
  username = "postgres"
  port     = "5432"


  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.security_group.security_group_id]
  # DB subnet group

  create_db_option_group    = false
  create_db_parameter_group = false

  create_db_subnet_group = true
  subnet_ids             = var.database_subnets


  deletion_protection = false
  publicly_accessible = true
  skip_final_snapshot = true

  tags = local.tags
}


data "aws_secretsmanager_secret" "db-secret" {
  arn = module.db.db_instance_master_user_secret_arn
}
data "aws_secretsmanager_secret_version" "current-db-secret-version" {
  secret_id = data.aws_secretsmanager_secret.db-secret.id
}
locals {
  db-password = jsondecode(data.aws_secretsmanager_secret_version.current-db-secret-version.secret_string)["password"]
}