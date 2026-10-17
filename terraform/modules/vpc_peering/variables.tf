variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "peer_vpc_id" {
  type = string
}

variable "peer_vpc_cidr" {
  type = string
}

variable "local_route_table_ids" {
  type = list(string)
}

variable "peer_route_table_ids" {
  type = list(string)
}
