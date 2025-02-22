data "aws_ssm_parameter" "config-domain" {
  name = "/${var.project}/config/domain"
}
data "aws_ssm_parameter" "config-stripe" {
  name = "/${var.project}/config/stripe"
}
data "aws_ssm_parameter" "config-kc" {
  name = "/${var.project}/config/kc"
}
data "aws_ssm_parameter" "config-pods" {
  name = "/${var.project}/config/pods"
}

locals {
  domain                  = nonsensitive(jsondecode(data.aws_ssm_parameter.config-domain.value).domain)
  stripeKey               = jsondecode(data.aws_ssm_parameter.config-stripe.value).stripeKey
  stripeWebhockSigningKey = jsondecode(data.aws_ssm_parameter.config-stripe.value).stripeWebhockSigningKey
  kcUsername              = jsondecode(data.aws_ssm_parameter.config-kc.value).username
  kcPassword              = jsondecode(data.aws_ssm_parameter.config-kc.value).password
  xpods                   = jsondecode(data.aws_ssm_parameter.config-pods)
}
