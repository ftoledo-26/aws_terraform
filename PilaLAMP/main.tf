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

// Creacion de la red de seguridad como dice el profe
resource "aws_security_group" "ssh" {
    name = "ssh-demo-lamp"
    description = "Allow SSH traffic"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
    cidr_ipv4 = "0.0.0.0/0"
    to_port = 22
    from_port = 22
    ip_protocol = "TCP"
    security_group_id = aws_security_group.ssh.id  
}

resource "aws_security_group" "http" {
    name = "http-demo-lamp"
    description = "Allow Http traffic"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
    cidr_ipv4 = "0.0.0.0/0"
    to_port = 80
    from_port = 80
    ip_protocol = "TCP"
    security_group_id = aws_security_group.http.id  
}

resource "aws_security_group" "all" {
    name = "all-demo-lamp"
    description = "Allow All Egress traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    security_group_id = aws_security_group.all.id  
}

resource "aws_security_group" "db" {
    name = "db-demo-lamp"
    description = "Allow DB ingress traffic"
}
resource "aws_security_group" "wsmysql" {
    name = "wsmysql-demo-lamp"
    description = "Identify Web Server connect to db"
}
resource "aws_vpc_security_group_ingress_rule" "db" {
    referenced_security_group_id = aws_security_group.wsmysql.id
    to_port = 3306
    from_port = 3306
    ip_protocol = "TCP"
    security_group_id = aws_security_group.db.id  
}




// Creacion de las instancias
resource "aws_instance" "ServidorWeb" {
  ami           = "ami-0ecb62995f68bb549"
  instance_type = "t2.small"
  // Nombre del par de claves
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.all.id, aws_security_group.http.id, aws_security_group.wsmysql.id]
  tags = {
    Name = "ServidorWeb"
  }
  user_data = file("install_apache.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "DBServer" {
  ami           = "ami-0ecb62995f68bb549"
  instance_type = "t2.small"
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.all.id, 
  aws_security_group.db.id]
  tags = {
    Name = "DBServer"
  }
  user_data = file("install_mysql.sh")
  user_data_replace_on_change = true
}

/*resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  tags = {
    Name = "web-elastic-ip"
  }
}*/