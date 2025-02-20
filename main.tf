provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}



locals {
  store_core_namespace = "store-core.${var.project}.lcl"
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = var.env
  }
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry

  pods = {

  }

}

data "aws_ssm_parameter" "config-domain" {
  name = "/${var.project}/config/domain"
}
data "aws_ssm_parameter" "config-stripe" {
  name = "/${var.project}/config/stripe"
}

locals {
  domain               = jsonencode(data.aws_ssm_parameter.config-domain.value).domain
  domainCertificateArn = jsonencode(data.aws_ssm_parameter.config-domain.value).domainCertificateArn
  key = jsonencode(data.aws_ssm_parameter.config-stripe.value).key
  signingKey = jsonencode(data.aws_ssm_parameter.config-stripe.value).signingKey

}
data "aws_route53_zone" "domain_zone" {
  name = jsonencode(data.aws_ssm_parameter.config-domain.value).domain
}

module "store-core" {
  source                     = "./store-core"
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnets
  private_subnets            = module.vpc.private_subnets
  log_s3_bucket_id           = module.log-bucket.s3_bucket_id
  domain                     = local.domain
  certificate_arn            = local.domainCertificateArn
  domain_zone_name           = data.aws_route53_zone.domain_zone.name
  project                    = var.project
  tags                       = local.tags
  database_subnets           = module.vpc.database_subnets
  vpc_cidr_block             = local.vpc_cidr
  env                        = var.env
  image_tag                  = var.image_tag
  namespace                  = local.store_core_namespace
  pods                       = local.pods
  stripe_key                 = local.key
  stripe_webhook_signing_key = local.signingKey
  docker_registry            = local.docker_registry
}

module "store-pod" {
  source               = "./store-pod"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnets
  private_subnets      = module.vpc.private_subnets
  log_s3_bucket_id     = module.log-bucket.s3_bucket_id
  domain               = local.domain
  certificate_arn      = local.domainCertificateArn
  store_core_namespace = local.store_core_namespace
  domain_zone_name     = data.aws_route53_zone.domain_zone.name
  project              = var.project
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
