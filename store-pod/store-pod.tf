locals {
  module_name     = "store-pod-${var.index}"
  cluster_dnsname = "${local.module_name}.${var.project}.lcl"

}
