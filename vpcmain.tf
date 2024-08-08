resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = var.tags
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  tags                    = var.tags
}

resource "aws_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  tags       = var.tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id
  tags          = var.tags
}

resource "aws_eip" "main" {
  vpc  = true
  tags = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = var.tags
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Example Security Group with best practices
resource "aws_security_group" "web_server" {
  name = "web_server_sg"
  vpc_id = aws_vpc.main.id
  tags   = var.tags

  # Allow HTTP traffic from within the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow HTTPS traffic from within the VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic (consider restricting this)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Example Network ACL with best practices
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags

  # Allow HTTP traffic from within the VPC
  ingress {
    protocol  = "tcp"
    rule_no   = 100
    action    = "allow"
    cidr_block = var.vpc_cidr
    from_port = 80
    to_port   = 80
  }

  # Allow HTTPS traffic from within the VPC
  ingress {
    protocol  = "tcp"
    rule_no   = 101
    action    = "allow"
    cidr_block = var.vpc_cidr
    from_port = 443
    to_port   = 443
  }

  # Allow ephemeral ports for return traffic (TCP)
  ingress {
    protocol  = "tcp"
    rule_no   = 102
    action    = "allow"
    cidr_block = var.vpc_cidr
    from_port = 1024
    to_port   = 65535
  }

  # Allow all outbound traffic (consider restricting this)
  egress {
    protocol  = "tcp"
    rule_no   = 100
    action    = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port   = 65535
  }

  # Deny all other inbound traffic
  ingress {
    protocol  = "-1" # All protocols
    rule_no   = 200
    action    = "deny"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port   = 65535
  }

  # Deny all other outbound traffic (consider restricting this)
  egress {
    protocol  = "-1" # All protocols
    rule_no   = 200
    action    = "deny"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port   = 65535
  }
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "The IDs of the private subnets"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "The IDs of the public subnets"
}
