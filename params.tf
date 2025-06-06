variable "region" {
  type = string
}
variable "env" {
  type = string
}
variable "docker_registry" {
  type = string
  default = ""
}
variable "image_tag" {
  type = string
}
variable "project" {
  type = string
}