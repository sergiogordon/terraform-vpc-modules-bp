variable "vpc_cidr" {
  type = string
  description = "The CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  description = "A list of CIDR blocks for the public subnets"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "A list of CIDR blocks for the private subnets"
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_dns_support" {
  type = bool
  description = "Whether to enable DNS support in the VPC"
  default = true
}

variable "enable_dns_hostnames" {
  type = bool
  description = "Whether to enable DNS hostnames in the VPC"
  default = true
}

variable "tags" {
  type = map(string)
  description = "A map of tags to assign to the resources"
  default = {
    Environment = "dev"
    Owner       = "your-name"
  }
}
