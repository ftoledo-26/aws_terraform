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
  instance_type = "t2.large" //Se puede poner en variables.tf
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

/////////////////////////Routes 53//////////////////////
/*resource "aws_route53_zone" "default" {
  name = "prueba.com" //Puede ir en variables usando el type string y default = "prueba.com"
  vpc{
    vpc_id = data.aws_vpc.default_vpc.id
    vpc_region = var.region
  }
}*/
resource "aws_route53_zone" "public_zone" {
  name = "prueba.com"
}
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.public_zone.id
  name = "frontend.prueba.com" /// Puede ir en variables usando el type string y default = "frontend.prueba.com"
  type = "A"
  ttl = 3600
  records = [aws_eip.frontend_eip.public_ip]
  //records = [aws_instance.frontend.public_ip]
}

resource "aws_route53_record" "frontend_alias" {
  zone_id = aws_route53_zone.public_zone.id
  name = "www.frontend.prueba.com" /// Puede ir en variables usando el type string y default = "www.frontend.prueba.com" usando ${}
  type = "A"
  ttl = 3600
  records = [aws_eip.frontend_eip.public_ip]
  //records = [aws_instance.frontend.public_ip]
}

/////////////////////////Ip Elastic//////////////////////
resource "aws_eip" "frontend_eip" {
  instance = aws_instance.frontend.id
  tags = {
    Name = "Frontend_EIP"
  }
}

/////////////////////////HTTPS/////////////////////
/*
# 1️⃣ Certificado ACM
resource "aws_acm_certificate" "ssl" {
  domain_name       = "frontend.prueba.com"
  validation_method = "DNS"
}

# 2️⃣ Validación automática vía Route53
resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.ssl.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.ssl.domain_validation_options[0].resource_record_type
  zone_id = aws_route53_zone.public_zone.zone_id
  ttl     = 60
  records = [aws_acm_certificate.ssl.domain_validation_options[0].resource_record_value]
}

# 3️⃣ Application Load Balancer
resource "aws_lb" "frontend" {
  name               = "frontend-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids
}

# 4️⃣ Target Group apuntando a la EC2 (HTTP 80)
resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default_vpc.id
  target_type = "instance"
}

# 5️⃣ Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ssl.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# 6️⃣ Registro Route53 apuntando al ALB
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "frontend.prueba.com"
  type    = "A"

  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}
*/