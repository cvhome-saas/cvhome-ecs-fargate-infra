variable "region" {
  type = string
}
variable "env" {
  type = string
}
variable "docker_registry" {
  type = string
}
variable "image_tag" {
  type = string
}
variable "project" {
  type = string
}
variable "pods" {
  type = map(object({
    index : number
    id : string
    name : string
    org : string
    endpoint : string
    endpointType : string
    size : string
  }))
}