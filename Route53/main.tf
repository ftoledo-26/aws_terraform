terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
//security Group ssh
resource "aws_security_group" "ssh" {
    name = "ssh-demo-lamp"
    description = "Allow SSH traffic"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_web" {
  cidr_ipv4 = "0.0.0.0/0"
  to_port = 22
  from_port = 22
  ip_protocol = "TCP"
  security_group_id = aws_security_group.ssh.id 
}
// Sedcurity group http
resource "aws_security_group" "http" {
    name = "http-all"
    description = "Allow all http"
}
resource "aws_vpc_security_group_ingress_rule" "http_web" {
  cidr_ipv4 = "0.0.0.0/0"
  to_port = 80
  from_port = 80
  ip_protocol = "TCP"
  security_group_id = aws_security_group.http.id
}

// Security group all 
resource "aws_security_group" "all" {
  name = "all-secure"
  description = "Allaw all egrees rule"
}
resource "aws_vpc_security_group_egress_rule" "all_web" {
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
  security_group_id = aws_security_group.all.id
}

//Instancia
resource "aws_instance" "ServidorWeb" {
  ami           = "ami-0ecb62995f68bb549"
  instance_type = "t2.small"
  // Nombre del par de claves
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.ssh.id, 
                            aws_security_group.all.id, 
                            aws_security_group.http.id]
  tags = {
    Name = "ServidorWeb"
  }
  user_data = file("./scripts/install_apache.sh")
  user_data_replace_on_change = true
}

// DNS 
resource "aws_route53_zone" "main" {
  name = "FranciscoToledoPerez.com"
}

resource "aws_route53_zone" "dev" {
  name = "FranciscoToledoPerez.com"

  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "web.franciscotoledoperez.local"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ServidorWeb.public_ip]
}