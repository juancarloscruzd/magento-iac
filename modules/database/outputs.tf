output "master_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.master.this_db_instance_endpoint
}

output "master_db_instance_name" {
  description = "The database name"
  value       = module.master.this_db_instance_name
}

output "master_db_instance_username" {
  description = "The master username for the database"
  value       = module.master.this_db_instance_username
}

output "master_db_instance_password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = module.master.this_db_instance_password
}

output "master_db_instance_port" {
  description = "The database port"
  value       = module.master.this_db_instance_port
}