variable "instance_type" {
  	type = string
	description = "Type for the instance EC2"
	default = "t2.small"
}
variable "key_name" {
  type = string
  default = "vockey"
}

variable "region2" {
	type = string
  	default = "us-east-1"
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
	name = "virtualization-type"
	values = [ "hvm" ]
  }
}

data "aws_vpc" "default_vpc" {
	default = true
	region = var.region2
}


variable "domain" {
	description = "Name of domain"
  type        = string
  default = "opavoloko.es"
}