terraform {
    required_providers {
        aws={
            source = "hashicorp/aws"
            version = "6.21.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
  
}

///////////////////Security Group SSH////////////////////
resource "aws_security_group" "ssh_apache" {
    description = "Allow SSH trafics"
    name = "ssh-demo-apache"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_apache_ingress" {
    security_group_id = aws_security_group.ssh_apache.id
    to_port           = 22
    from_port         = 22
    ip_protocol       = "TCP"
    cidr_ipv4         = "0.0.0.0/0"
}
//////////////////////Security group http////////////////////
resource "aws_security_group" "apache_http" {
    name = "http-demo-apache"
    description = "Allow Http trafics"
}
resource "aws_vpc_security_group_ingress_rule" "http_apache_ingress" {
  from_port         = 80
  to_port           = 80
  ip_protocol = "TCP"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.apache_http.id
}
//////////////////////egress rules////////////////////
resource "aws_security_group" "all" {
    name = "all"
    description = "Allow all traffic"
}
resource "aws_vpc_security_group_egress_rule" "all_egress" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
    security_group_id = aws_security_group.all.id
}
//////////////////////instance////////////////////
resource "aws_instance" "apache_instance" {
    ami           =  "ami-0c398cb65a93047f2"
    instance_type = "t2.micro"
    key_name      = "vockey"
    vpc_security_group_ids = [
        aws_security_group.ssh_apache.id,
        aws_security_group.apache_http.id,
        aws_security_group.all.id
    ]
    user_data = file("script.sh")
    user_data_replace_on_change = true
    tags = {
        Name = "ApacheInstance"
    }
}