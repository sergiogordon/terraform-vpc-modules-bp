# provider.tf
provider "aws" {
  region = "us-east-1"
}

# variables.tf
variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  default     = "social-feed-app"
}

# main.tf
module "modules-bp" {
  source  = "app.terraform.io/Gordons-Cloud/modules-bp/vpc"
  version = "1.0.0"

  key_pair_name = var.key_pair_name
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

resource "aws_security_group" "socialfeed_sg" {
  name   = "socialfeed-sg"
  vpc_id = module.modules-bp.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
    Name        = "socialfeed-sg"
    environment = "dev"
    owner       = "team-a"
  }
}

resource "aws_instance" "socialfeed_ec2" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  subnet_id                   = module.modules-bp.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.socialfeed_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              amazon-linux-extras install nginx1
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name        = "socialfeed-ec2"
    environment = "dev"
    owner       = "team-a"
  }
}

resource "aws_eip" "socialfeed_eip" {
  domain   = "vpc"
  instance = aws_instance.socialfeed_ec2.id
  depends_on = [module.modules-bp.internet_gateway]

  tags = {
    Name        = "socialfeed-eip"
    environment = "dev"
    owner       = "team-a"
  }
}

# outputs.tf
output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.socialfeed_ec2.public_ip
}

output "ec2_instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.socialfeed_ec2.public_dns
}

output "eip_public_ip" {
  description = "Public IP address of the Elastic IP"
  value       = aws_eip.socialfeed_eip.public_ip
}

terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      name = "socialfeed-app-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  sentinel_policies = {
    "compliance" = <<-EOT
${file("compliance-policy.sentinel")}
EOT
    "cost"       = <<-EOT
${file("cost-policy.sentinel")}
EOT
  }
}
