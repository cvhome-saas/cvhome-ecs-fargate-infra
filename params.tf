variable "region" {
  type = string
}
variable "env" {
  type = string
}
variable "domain" {
  type = string
}
variable "domain_certificate_arn" {
  type = string
}
variable "docker_registry" {
  type = string
}
variable "image_tag" {
  type = string
}
variable "stripe_key" {
  type = string
}
variable "stripe_webhook_signing_key" {
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