module "letsencrypt-proxy" {
  source    = ".././common/proxy-lambda"
  name      = "letsencrypt-proxy-${var.project}-${var.pod.id}-${var.env}"
  proxy_url = "https://acme-v02.api.letsencrypt.org"
}
