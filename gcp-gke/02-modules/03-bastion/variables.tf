variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "vpc_self_link" { type = string }
variable "subnet_self_link" { type = string }
variable "bastion_name" { type = string }
variable "machine_type" { type = string }
variable "disk_size_gb" { type = number }
variable "tags" {
  type    = map(string)
  default = {}
}