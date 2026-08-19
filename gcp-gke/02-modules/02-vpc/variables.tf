variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "create_vpc" {
  type    = bool
  default = true
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "pod_range_name" {
  type = string
}

variable "pod_range_cidr" {
  type = string
}

variable "svc_range_name" {
  type = string
}

variable "svc_range_cidr" {
  type = string
}