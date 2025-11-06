data "aws_ssm_parameter" "config-cvhome" {
  name = "/${var.project}/config/cvhome"
}

locals {
  hosted_zone_id = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).hosted_zone_id)
  env = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).env)
  image_tag = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).image_tag)
  pod_count = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).pod_count)
  pod_size = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).pod_size)
}
