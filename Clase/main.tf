terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "6.21.0"
    }
  }
}

provider "aws" {
  region = var.region2
}


resource "aws_security_group" "ssh" {
    name = "ssh-demo-lamp"
    description = "Allow SSH traffic"
    vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh.id
}

resource "aws_security_group" "http" {
    name = "http-demo-lamp"
    description = "Allow Http traffic"
    vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.http.id
}

resource "aws_security_group" "all" {
    name = "all-demo-lamp"
    description = "Allow All Egress traffic"
    vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.all.id
}

resource "aws_instance" "web_server" {
  instance_type = var.instance_type
  key_name = var.key_name
  ami = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [
    aws_security_group.all.id,
    aws_security_group.http.id,
    aws_security_group.ssh.id,
  ]
  user_data = file("web_server_user_data.sh")
  user_data_replace_on_change = true
  tags = {
    Name  = "Web_server_Rute53"
  }
}

resource "aws_instance" "bastion" {
  instance_type = var.instance_type
  key_name = var.key_name
  ami = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.all.id,
  ]
  tags = {
    Name = "bastion"
  }
}

resource "aws_route53_zone" "default" {
  name = var.domain

  vpc {
    vpc_id     = data.aws_vpc.default_vpc.id
    vpc_region = var.region2
  }
}

resource "aws_route53_record" "web_server" {
  zone_id = aws_route53_zone.default.id
  name    = var.domain
  type    = "A"
  ttl     = 3600
  records = [aws_instance.web_server.private_ip]
}

resource "aws_route53_record" "web_server_alias" {
  zone_id = aws_route53_zone.default.id
  name    = "www.${var.domain}"
  type    = "A"
  ttl     = 3600
  records = [aws_instance.web_server.private_ip]
}

resource "aws_route53_record" "bastion" {
  type = "A"
  name = "bastion.${var.domain}"
  zone_id = aws_route53_zone.default.id
  ttl = 3600
  records = [ aws_instance.bastion.private_ip]
}
