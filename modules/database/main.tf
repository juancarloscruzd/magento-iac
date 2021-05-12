locals {
  engine            = "mysql"
  engine_version    = "8.0.20"
  major_engine_version = "8.0"
  instance_class    = "db.t2.small"
  allocated_storage = 5
  port              = "3306"
}

resource "aws_security_group" "rds-in" {
  name   = "Magento - RDS"
  vpc_id = var.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "App" = "magento"
    "Name" = "magento-rds-sg"
    "Environment" = var.environment
  }
}

module "master" {
  source            = "terraform-aws-modules/rds/aws"
  identifier        = "magento-master-mysql"

  engine            = local.engine
  engine_version    = local.engine_version
  instance_class    = local.instance_class
  allocated_storage = local.allocated_storage
  major_engine_version = local.major_engine_version

  name     = "magentodb"
  username = "magento"
  password = "pjvgwN6dCagHZ5wL"
  port     = local.port

  vpc_security_group_ids = [aws_security_group.rds-in.id]
  
  maintenance_window = "Tue:00:00-Tue:03:00"
  backup_window      = "03:00-06:00"

  multi_az = true

  # Backups are required in order to create a replica
  backup_retention_period = 1

  # DB subnet group
  db_subnet_group_name = var.db_subnet_group


  create_db_option_group    = false
  create_db_parameter_group = false
  parameter_group_name = "magento-default-parameter-group"
 

}


module "replica" {
  source            = "terraform-aws-modules/rds/aws"
  //depends_on        = [module.master]

  identifier = "magento-replica-mysql"

  # Source database. For cross-region use this_db_instance_arn
  replicate_source_db = module.master.this_db_instance_id

  engine            = local.engine
  engine_version    = local.engine_version
  instance_class    = local.instance_class
  allocated_storage = local.allocated_storage
  major_engine_version = local.major_engine_version

  # Username and password should not be set for replicas
  username = ""
  password = ""
  port     = local.port

  vpc_security_group_ids = [aws_security_group.rds-in.id]

  maintenance_window = "Tue:00:00-Tue:03:00"
  backup_window      = "03:00-06:00"

  multi_az = false

  # disable backups to create DB faster
  backup_retention_period = 0

  # Not allowed to specify a subnet group for replicas in the same region
  create_db_subnet_group = false

  create_db_option_group    = false
  create_db_parameter_group = false
  parameter_group_name = "magento-default-parameter-group"
}