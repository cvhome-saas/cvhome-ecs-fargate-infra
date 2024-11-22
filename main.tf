provider "aws" {
  region  = var.region
}

data "aws_caller_identity" "current" {}

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
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry
}

data "aws_route53_zone" "domain_zone" {
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
  domain_zone_name = data.aws_route53_zone.domain_zone.name
  project          = local.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  image_version    = var.image_version
  namespace        = "store-core.${local.project}.lcl"
  docker_registry  = local.docker_registry
}

module "store-pod" {
  source           = "./store-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  domain_zone_name = data.aws_route53_zone.domain_zone.name
  project          = local.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  docker_registry  = local.docker_registry
  image_version    = var.image_version
  namespace        = "store-pod-${each.key}.${local.project}.lcl"
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
  domain_zone_name = data.aws_route53_zone.domain_zone.name
  project          = local.project
  tags             = local.tags
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  docker_registry  = local.docker_registry
  image_version    = var.image_version
  namespace        = "saas-pod-${each.key}.${local.project}.lcl"
  for_each         = toset(["1"])
}