data "aws_secretsmanager_secret" "stripe" {
  name = "/${var.project}/config/stripe"
}
data "aws_secretsmanager_secret" "kc" {
  name = "/${var.project}/config/kc"
}
