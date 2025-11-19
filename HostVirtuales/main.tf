terraform {
  backend "s3" {
    key = "terraform.tfstate"
    bucket = "2dawbucket"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"

}

resource "aws_security_group" "demo_terra" {
  name        = "demo_terra"
  description = "Permitir HTTP y SSH"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo_terra"
  }
}


resource "aws_instance" "instancia" {
  vpc_security_group_ids = [aws_security_group.demo_terra.id]

  ami           = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.micro"
  key_name = "demo"
  tags = {
    name = "demo_instancia"
  }
  user_data = file("install_apache.sh")
  user_data_replace_on_change = true
}
