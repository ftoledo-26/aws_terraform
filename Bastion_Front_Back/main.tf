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

///////////////////Security Group SSH////////////////////
resource "aws_security_group" "ssh_bastion" {
    description = "Allow SSH trafics"
    name = "ssh-demo-bastion"
}
resource "aws_security_group" "ssh_palresto" {
    description = "Allow SSH traffic from Palresto"
    name = "ssh-demo-palresto"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_bastion" {
    security_group_id = aws_security_group.ssh_bastion.id
    to_port           = 22
    from_port         = 22
    ip_protocol       = "TCP"
    cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_palresto" {
    from_port = 22
    to_port = 22
    ip_protocol = "TCP"
    security_group_id = aws_security_group.ssh_palresto.id
    referenced_security_group_id = aws_security_group.ssh_bastion.id
}
//////////////////////Security group http////////////////////
resource "aws_security_group" "frontend_http" {
    name = "http-demo-frontend"
    description = "Allow Http trafics"
}
resource "aws_vpc_security_group_ingress_rule" "http_ingress" {
  from_port         = 80
  to_port           = 80
  ip_protocol = "TCP"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.frontend_http.id
}

resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Only allow HTTP from frontend"
}

resource "aws_vpc_security_group_ingress_rule" "backend_http_from_frontend" {
  security_group_id             = aws_security_group.backend.id
  referenced_security_group_id  = aws_security_group.frontend_http.id
  ip_protocol                   = "tcp"
  from_port                     = 80
  to_port                       = 80
}
////////////////////// Security group all egress////////////////////
resource "aws_security_group" "all" {
    name = "all-demo-bastion"
    description = "Allow All Egress trafics"
}
resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id   = aws_security_group.all.id
  ip_protocol          = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

////////////////////////Frontend Instance////////////////////////
resource "aws_instance" "frontend" {
  instance_type = "t2.large"
  ami = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [
    aws_security_group.all.id,
    aws_security_group.frontend_http.id,
    aws_security_group.ssh_palresto.id
  ]
  user_data = templatefile("frontend.sh", {
    backend_ip = aws_instance.backend.private_ip
  })
  user_data_replace_on_change = true
  tags = {
    Name = "Frontend-Instance"
  }
  depends_on = [aws_instance.backend]
}

////////////////////////Backend Instance////////////////////////
resource "aws_instance" "backend" {
  instance_type = "t2.large"
  ami = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [
    aws_security_group.all.id,
    aws_security_group.ssh_palresto.id,
    aws_security_group.backend.id
    ]
    user_data = file("backend.sh")
    user_data_replace_on_change = true
    tags = {
        Name = "Backend-Instance"
    }
}
/////////////////////////Bastion Instance////////////////////////
resource "aws_instance" "bastion" {
  instance_type = "t2.micro"
  ami = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [
    aws_security_group.all.id,
    aws_security_group.ssh_bastion.id
  ]
  tags = {
    Name = "Bastion-Instance"
  }
}