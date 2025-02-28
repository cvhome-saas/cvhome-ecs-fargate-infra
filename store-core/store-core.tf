locals {
  module_name = "store-core"
}
resource "random_password" "password" {
  length           = 16
  special          = false
}
