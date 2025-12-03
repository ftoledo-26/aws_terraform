terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "6.21.0"
      }
    }
}
provider "aws" {
    region = var.region
}


/////////////////////Security Group Bastion////////////////////
resource "aws_security_group" "Bastion_sg" {
    description = "Allow SSH from internet to Bastion"
    name        = "bastion-sg"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_ingress" {
    security_group_id = aws_security_group.Bastion_sg.id
    to_port           = 22
    from_port         = 22
    ip_protocol       = "TCP"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
    security_group_id = aws_security_group.Bastion_sg.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}

/////////////////////Security Group Frontend////////////////////
resource "aws_security_group" "frontend_sg" {
    description = "Allow HTTP from internet and SSH from Bastion"
    name        = "frontend-sg"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_http_ingress" {
    security_group_id = aws_security_group.frontend_sg.id
    to_port           = 80
    from_port         = 80
    ip_protocol       = "TCP"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_ssh_from_bastion" {
    security_group_id = aws_security_group.frontend_sg.id
    to_port           = 22
    from_port         = 22
    ip_protocol       = "TCP"
    referenced_security_group_id = aws_security_group.Bastion_sg.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_egress" {
    security_group_id = aws_security_group.frontend_sg.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}

/////////////////////Security Group Backend////////////////////
resource "aws_security_group" "backend_sg" {
    description = "Allow HTTP from Frontend and SSH from Bastion"
    name        = "backend-sg"
}

resource "aws_vpc_security_group_ingress_rule" "backend_http_from_frontend" {
    security_group_id = aws_security_group.backend_sg.id
    to_port           = 80
    from_port         = 80
    ip_protocol       = "TCP"
    referenced_security_group_id = aws_security_group.frontend_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_ssh_from_bastion" {
    security_group_id = aws_security_group.backend_sg.id
    to_port           = 22
    from_port         = 22
    ip_protocol       = "TCP"
    referenced_security_group_id = aws_security_group.Bastion_sg.id
}

resource "aws_vpc_security_group_egress_rule" "backend_egress" {
    security_group_id = aws_security_group.backend_sg.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}


//////////////////Instance Backend////////////////////
resource "aws_instance" "BACKEND" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  user_data = file("backend.sh")
  user_data_replace_on_change = true
    tags = {
        Name = "Backend_Server"
    }
}

//////////////////Instance Frontend////////////////////
resource "aws_instance" "FRONTEND" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  user_data = templatefile("frontend.sh", {
    backend_ip = aws_instance.BACKEND.private_ip
  })
  user_data_replace_on_change = true
    tags = {
        Name = "FrontEnd_Server"
    }
}


///////////////////Bastion Host Instance////////////////////
resource "aws_instance" "BASTION" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.Bastion_sg.id]
    tags = {
        Name = "Bastion_Host"
    }
}