variable "key_pair" { default = "11" }

variable "region" {
  type = string
  default = "ap-northeast-2"
}

variable "cidr" {
  type = string
  default = "80.0.0.0/16"
}

variable "service_name" {
  type = string
  default = "terraform"
}

variable "t3" { default = "t3.micro" }
variable "gp3" { default = "gp3" }