data "aws_availability_zones" "available" {}
locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-${var.env}"
  cidr = local.vpc_cidr


  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}

module "bastion" {
  source = "umotif-public/bastion/aws"
  version = "~> 2.1.0"

  name_prefix = var.project

  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets

  ssh_key_name   = var.bastion_ssh_key_name

  tags = local.tags
}