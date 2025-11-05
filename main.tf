provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "domain_zone" {
  zone_id = local.hosted_zone_id
}

data "aws_acm_certificate" "certificate" {
  domain = data.aws_route53_zone.domain_zone.name
  statuses = ["ISSUED"]
}

locals {
  store_core_namespace = "store-core.${var.project}.lcl"
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = local.env
  }
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project}"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry
  xpods = [
    {
      index : 0
      id : "1"
      name : "default",
      size : "large"
    },
  ]
  pods = {
    for value in local.xpods : lookup(value, "name") => {
      index : lookup(value, "index")
      id : lookup(value, "id")
      name : lookup(value, "name")
      org : try(lookup(value, "org"), "")
      endpoint : "https://store-pod-${lookup(value, "id")}.${data.aws_route53_zone.domain_zone.name}"
      namespace : "store-pod-${lookup(value, "id")}.${var.project}.lcl"
      size : try(lookup(value, "size"), "large"),
      endpointType : "EXTERNAL"
    }
  }
}


module "store-core" {
  source                     = "./store-core"
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnets
  private_subnets            = module.vpc.private_subnets
  log_s3_bucket_id           = module.log-bucket.s3_bucket_id
  domain                     = data.aws_route53_zone.domain_zone.name
  certificate_arn            = data.aws_acm_certificate.certificate.arn
  project                    = var.project
  tags                       = local.tags
  database_subnets           = module.vpc.database_subnets
  vpc_cidr_block             = local.vpc_cidr
  env                        = local.env
  image_tag                  = local.image_tag
  namespace                  = local.store_core_namespace
  pods                       = local.pods
  docker_registry            = local.docker_registry
}

module "store-pod" {
  source               = "./store-pod"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnets
  private_subnets      = module.vpc.private_subnets
  log_s3_bucket_id     = module.log-bucket.s3_bucket_id
  domain               = data.aws_route53_zone.domain_zone.name
  certificate_arn      = data.aws_acm_certificate.certificate.arn
  store_core_namespace = local.store_core_namespace
  domain_zone_name     = data.aws_route53_zone.domain_zone.name
  project              = var.project
  tags                 = local.tags
  database_subnets     = module.vpc.database_subnets
  vpc_cidr_block       = local.vpc_cidr
  env                  = local.env
  docker_registry      = local.docker_registry
  image_tag            = local.image_tag
  test_stores          = each.key == "default"
  pod                  = each.value
  for_each             = local.pods
}
