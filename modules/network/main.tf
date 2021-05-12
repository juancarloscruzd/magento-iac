variable "app_name" {
}

variable "environment" {
}

variable "azs" {
  type = list(string)
}

variable "database_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.15.0"
  name    = "magento-vpc"
  cidr    = "10.0.0.0/16"

  azs              = var.azs
  
  database_subnets = var.database_subnets
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  vpc_tags = {
    Terraform   = "true"
    Environment = var.environment
    App         = var.app_name
  }

  public_subnet_tags = { 
    Name        = join("-", [var.app_name, "public-subnet"])
    Environment = var.environment
    App         = var.app_name
    Tier        = "Public"
  }

  private_subnet_tags = {
    Name        = join("-", [var.app_name, "private-subnet"])
    Environment = var.environment
    App         = var.app_name
    Tier        = "Private"
  }

}

//Parameter group for the RDS databases
resource "aws_db_parameter_group" "default" {
  name   = "magento-default-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "time_zone"
    value = "US/Central"
  }
}