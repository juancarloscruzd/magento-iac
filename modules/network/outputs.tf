output "vpc_id" {
  value = module.vpc.vpc_id
}

output "db_subnet_group_name" {
  value = module.vpc.database_subnet_group
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "database_subnets" {
  value = module.vpc.database_subnets
}