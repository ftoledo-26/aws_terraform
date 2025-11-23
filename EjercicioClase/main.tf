terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "6.21.0"
    }
  }
}

provider "aws" {
  region = var.region
}

//////////////////Security Group SSH////////////////////
resource "aws_security_group" "ssh" {
  description = "Allow SSH trafics"
  name = "ssh-demo"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.ssh.id
  to_port = 22
  from_port = 22
  ip_protocol = "TCP"
  cidr_ipv4 = "0.0.0.0/0"
}
//////////////////Security Group HTTP////////////////////
resource "aws_security_group" "http" {
  description = "Allow HTTP trafics"
  name = "http-demo"
}

resource "aws_vpc_security_group_ingress_rule" "http_ingress" {
  security_group_id = aws_security_group.http.id
  to_port = 80
  from_port = 80
  ip_protocol = "TCP"
  cidr_ipv4 = "0.0.0.0/0"
}

//////////////////Security Group ALL EGRESS////////////////////
resource "aws_security_group" "all" {
  description = "Allow All Egress trafics"
  name = "all-demo"
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.all.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

//////////////////Instancia Backend////////////////////
resource "aws_instance" "Backend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.all.id,
  ]
    user_data = file("back.sh")
    user_data_replace_on_change = true
    tags = {
      Name = "Backend_Server_Rute53"
    }
}

//////////////////Instancia Frontend////////////////////

resource "aws_instance" "Frontend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.all.id,
  ]
    user_data = file("front.sh")
    user_data_replace_on_change = true
    tags = {
      Name = "Frontend_Server_Rute53"
    }
}