#
# module "security_group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.0"
#
#   name        = "${var.project}-db-sg"
#   description = "Complete PostgreSQL example security group"
#   vpc_id = module.vpc.vpc_id
#
#   # ingress
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 5432
#       to_port     = 5432
#       protocol    = "tcp"
#       description = "PostgreSQL access from within VPC"
#       cidr_blocks = module.vpc.vpc_cidr_block
#     },
#   ]
#
#   tags = local.tags
# }
#
#
# module "db" {
#   source = "terraform-aws-modules/rds/aws"
#
#   identifier = "${var.project}-${var.env}"
#
#   engine            = "postgres"
#   engine_version    = "16.4"
#   instance_class    = "db.t4g.micro"
#   allocated_storage = 20
#   family = "postgres16"
#
#
#   db_name  = var.project
#   username = "postgres"
#   port     = "5432"
#
#
#   iam_database_authentication_enabled = false
#
#   vpc_security_group_ids = [module.security_group.security_group_id]
#   # DB subnet group
#
#   create_db_option_group    = false
#   create_db_parameter_group = false
#
#   create_db_subnet_group = true
#   subnet_ids = module.vpc.database_subnets
#
#
#   deletion_protection = false
#   publicly_accessible = true
#   skip_final_snapshot = true
#
#   tags = local.tags
# }
