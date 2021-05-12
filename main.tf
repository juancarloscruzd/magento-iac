
terraform {
   backend "s3" { 
    bucket         = "dev-princeshoes-terraform-remote-states"
    /*====
    IMPORTANT: key is the file path within the S3 bucket where the Terraform state file should be written
    IF this is a new project, change the "key" value to match the folder structure of this new project, otherwise,
    if it is a existing project and you are just improving the scripts, DO NOT CHANGE IT
    ======*/
    key            = "dev/6_magento/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dev-princeshoes-terraform-state-locks"
    encrypt        = true
  } 
  required_providers {
    aws = ">= 2.68"
  }
}

provider "aws" {
	region  = var.region
}

data "aws_caller_identity" "current" {}

# 0. Provision a training instance with Magento sample data
module "training_instance" {
  source           = "./modules/training_instance/"
  environment      = var.environment
  key_name         = module.pem.pem_file_name
  subnet_id        = element(module.network.public_subnets, 0)
  vpc_id           = module.network.vpc_id
}

# 1. Provision a pem file for all the computing resources
module "pem" {
  source           = "./modules/pem"
}

# 2. Provision a master_instance so an up-to-date Magento image can be created
# Feel free to comment and uncomment whenever is necesary
// module "master_instance" {
//   source           = "./modules/master_instance/"
//   environment      = var.environment
//   key_name         = module.pem.pem_file_name
//   subnet_id        = element(module.network.public_subnets, 0)
//   vpc_id           = module.network.vpc_id
// }

// 3. Full HA Magento stack from here

module "network" {
  source           = "./modules/network/"
  app_name         = var.app_name
  azs              = var.azs
  environment      = var.environment
  database_subnets = var.database_subnets
  public_subnets   = var.public_subnets
  private_subnets   = var.private_subnets
}

module "database" {
  source           = "./modules/database/"
  environment      = var.environment
  vpc_id           = module.network.vpc_id
  db_subnet_group  = module.network.db_subnet_group_name
}

module "efs" {
  source           = "./modules/efs/"
  app_name         = var.app_name
  vpc_id           = module.network.vpc_id
  public_subnets   = module.network.public_subnets
  environment      = var.environment
}

module "elasticsearch" {
  source                      = "./modules/elasticsearch"
  region                      = var.region
  vpc_id                      = module.network.vpc_id
  environment                 = var.environment
  subnet_ids                  = module.network.database_subnets
  account_id                  = data.aws_caller_identity.current.account_id
}

module "redis" {
  source                      = "./modules/redis"
  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.database_subnets
  environment                 = var.environment
 }

module "compute" {
  source           = "./modules/compute/"
  app_name         = var.app_name
  key_name         = module.pem.pem_file_name
  vpc_id           = module.network.vpc_id
  public_subnets   = module.network.public_subnets
  environment      = var.environment
  efs_host         = module.efs.efs_host
}

