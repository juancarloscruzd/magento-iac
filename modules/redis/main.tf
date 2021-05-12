resource "aws_security_group" "default" {
  name_prefix = "magento"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "elasticache-in" {
  name   = "Magento - Elasticache"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
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
    "Name" = "magento-elasticache-sg"
    "Environment" = var.environment
  }
}

resource "aws_elasticache_subnet_group" "default" {
  name       = "magento-cache-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "default" {
  replication_group_id          = "magento-redis-cluster"
  replication_group_description = "Redis cluster for Magento"

  availability_zones   = ["us-east-1a", "us-east-1b"]  

  node_type            = "cache.t2.small"
  port                 = 6379
  parameter_group_name = "default.redis6.x"
  
  number_cache_clusters  = 2

  snapshot_retention_limit = 5
  snapshot_window          = "00:00-05:00"

  security_group_ids        = [aws_security_group.elasticache-in.id]

  subnet_group_name          = aws_elasticache_subnet_group.default.name
  automatic_failover_enabled = true
}