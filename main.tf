provider "aws" {
  region = var.region
}

resource "random_string" "project" {
  length  = 8
  upper   = false
  lower   = true
  numeric = false
  special = false
}

locals {
  project = random_string.project.result
  tags = {
    Project     = local.project
    Terraform   = "true"
    Environment = var.env
  }
}

data "aws_route53_zone" "domain_zone_id" {
  name = var.domain
}

module "store-core" {
  source           = "./store-core"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  domain_zone_id   = data.aws_route53_zone.domain_zone_id.name
  project          = local.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  docker_registry = var.docker_registry
}

module "store-pod" {
  source           = "./store-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  domain_zone_id   = data.aws_route53_zone.domain_zone_id.name
  project          = local.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  docker_registry = var.docker_registry
  for_each         = toset(["1"])
}

module "saas-pod" {
  source           = "./sass-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  domain_zone_id   = data.aws_route53_zone.domain_zone_id.name
  project          = local.project
  tags             = local.tags
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  docker_registry = var.docker_registry
  for_each         = toset(["1"])
}