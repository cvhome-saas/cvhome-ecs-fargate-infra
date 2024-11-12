provider "aws" {
  region = "eu-central-1"
}

locals {
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = var.env
  }
}

module "store-core" {
  source           = "./store-core"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  project          = var.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
}

module "store-pod" {
  source           = "./store-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  project          = var.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  for_each = toset(["1"])
}

module "saas-pod" {
  source           = "./sass-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  certificate_arn  = var.certificate_arn
  domain           = var.domain
  project          = var.project
  tags             = local.tags
  vpc_cidr_block   = local.vpc_cidr
  env              = var.env
  index            = each.key
  for_each = toset(["1"])
}