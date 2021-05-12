data "aws_subnet_ids" "efs_subnets" {
  vpc_id = var.vpc_id

  tags = {
    App   = var.app_name
    Environment = var.environment
  }
}

resource "aws_security_group" "sg-EFS" {
  name   = "Magento - EFS"
  vpc_id = var.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "magento-efs" {
}

resource "aws_efs_mount_target" "magento-efs-mounts" {
  subnet_id       = element(var.public_subnets, count.index)
  file_system_id  = aws_efs_file_system.magento-efs.id
  security_groups = [aws_security_group.sg-EFS.id]
  count           = length(var.public_subnets)
}

