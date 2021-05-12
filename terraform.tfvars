#General vars
environment                   = "dev"
region                        = "us-east-1"
app_name                      = "magento" 

#Network
azs                           = ["us-east-1a","us-east-1b"]
public_subnets                = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets               = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnets              = ["10.0.101.0/24", "10.0.102.0/24"]

#Database vars
// database_name                 = "magentodb"
// database_username             = "admin"
// database_password             = "wqX6aJVPDWvcLM3TZWpx38"
// database_port                 = 3306
// amount_of_instances           = 1
// multi_az                      = false
// instance_class                = "db.t2.small"
// engine                        = "aurora-mysql"
// engine_version                = "5.7.mysql_aurora.2.07.2"
// publicly_accessible           = false