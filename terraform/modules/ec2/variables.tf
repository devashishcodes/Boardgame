variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs (har subnet me 1 instance)"
  type        = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}
