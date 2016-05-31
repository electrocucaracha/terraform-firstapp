variable "tenant_name" {}
variable "user_name" {}
variable "password" {}

variable "auth_url" {
  default = "http://8.43.86.2:5000/v2.0"
}

variable "region" {
  default = "RegionOne"
}

variable "image" {
  default = "Ubuntu14.04"
}

variable "flavor" {
  default = "m1.small"
}

variable "ssh_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "external_gateway" {
  default  = "1fd0a21e-e700-46ae-9f05-0b3164daafcc"
}
