data "aws_ssm_parameter" "config-domain" {
  name = "/${var.project}/config/domain"
}
data "aws_ssm_parameter" "config-stripe" {
  name = "/${var.project}/config/stripe"
}
data "aws_ssm_parameter" "config-kc" {
  name = "/${var.project}/config/kc"
}

locals {
  domain                  = nonsensitive(jsondecode(data.aws_ssm_parameter.config-domain.value).domain)
  domainCertificateArn    = jsondecode(data.aws_ssm_parameter.config-domain.value).domainCertificateArn
  stripeKey               = jsondecode(data.aws_ssm_parameter.config-stripe.value).stripeKey
  stripeWebhockSigningKey = jsondecode(data.aws_ssm_parameter.config-stripe.value).stripeWebhockSigningKey
  kcUsername              = jsondecode(data.aws_ssm_parameter.config-kc.value).username
  kcPassword              = jsondecode(data.aws_ssm_parameter.config-kc.value).password
}
