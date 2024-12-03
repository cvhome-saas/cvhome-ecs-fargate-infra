provider "aws" {
  region = var.region
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
  project              = random_string.project.result
  store_core_namespace = "store-core.${local.project}.lcl"
  tags = {
    Project     = local.project
    Terraform   = "true"
    Environment = var.env
  }
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry

  pods = {
    for key, value in var.pods : key => {
      index : lookup(value, "index")
      id : lookup(value, "id")
      name : "store-pod-${lookup(value, "index")}"
      org : lookup(value, "org")
      endpoint : lookup(value, "endpointType")=="EXTERNAL"?lookup(value, "endpoint"):"store-pod-${lookup(value, "id")}.${local.project}.lcl"
      endpointType : lookup(value, "endpointType")
      size : lookup(value, "size")
    }
  }

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
  image_tag        = var.image_tag
  namespace        = local.store_core_namespace
  pods             = local.pods
  docker_registry  = local.docker_registry
}

module "store-pod" {
  source               = "./store-pod"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnets
  private_subnets      = module.vpc.private_subnets
  log_s3_bucket_id     = module.log-bucket.s3_bucket_id
  certificate_arn      = var.certificate_arn
  domain               = var.domain
  store_core_namespace = local.store_core_namespace
  domain_zone_name     = data.aws_route53_zone.domain_zone.name
  project              = local.project
  tags                 = local.tags
  database_subnets     = module.vpc.database_subnets
  vpc_cidr_block       = local.vpc_cidr
  env                  = var.env
  docker_registry      = local.docker_registry
  image_tag            = var.image_tag
  test_stores          = each.key == "default"
  pod                  = each.value
  for_each             = local.pods
}
