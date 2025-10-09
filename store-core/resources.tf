module "stripe-proxy" {
  source = ".././common/proxy-lambda"
  name = "stripe-proxy${local.module_name}-${var.project}-${var.env}"
  proxy_url = "https://api.stripe.com"
}