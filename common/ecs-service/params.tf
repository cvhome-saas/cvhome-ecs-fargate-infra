variable "env" {
  type = string
}
variable "module_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "project" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "service_name" {
  type = string
}
variable "namespace_id" {
  type = string
}
variable "subnet" {
  type = list(string)
}


variable "tags" {
  type = map(string)
}
variable "requires_compatibilities" {
  type = list(string)
  default = [
    "FARGATE"
  ]
}
variable "service" {
  type = object({
    public : bool
    loadbalancer_target_groups : map(object({
      loadbalancer_target_groups_arn : string
      main_container : string
      main_container_port : number
    }))
    priority : number
    service_type : string
    load_balancer_host_matchers = list(string)
    desired : number
    cpu : string
    memory : string
    main_container : string
    main_container_port : number
    health_check : object({
      path : string
      port : number
      healthy_threshold : number
      interval : number
      unhealthy_threshold : number
    })
    containers : map(object({
      image : string
      environment : list(object({
        name : string
        value : string
      }))
      portMappings : list(object({
        name : string,
        containerPort : number,
        hostPort : number,
        protocol : string
      }))
    }))
  })
}
variable "ingress_with_cidr_blocks" {
  description = "List of ingress rules to create where 'cidr_blocks' is used"
  type        = list(map(string))
  default     = []
}
variable "egress_with_cidr_blocks" {
  description = "List of egress rules to create where 'cidr_blocks' is used"
  type        = list(map(string))
  default     = []
}
