output "store_ui_url" {
  value = module.store-core.store_ui_url
  sensitive = false
}
output "welcome_ui_url" {
  value = module.store-core.welcome_ui_url
  sensitive = false
}
output "auth_url" {
  value = module.store-core.auth_url
  sensitive = false
}
output "org1_store1_url" {
  value = "https://org1-store1.${module.store-pod["default"].domain}"
  sensitive = false
}
output "org1_store2_url" {
  value = "https://org1-store2.${module.store-pod["default"].domain}"
  sensitive = false
}
output "org2_store1_url" {
  value = "https://org2-store1.${module.store-pod["default"].domain}"
  sensitive = false
}
output "org2_store2_url" {
  value = "https://org2-store2.${module.store-pod["default"].domain}"
  sensitive = false
}
