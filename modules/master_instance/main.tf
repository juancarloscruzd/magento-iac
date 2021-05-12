resource "aws_security_group" "magento_master" {

  name = "magento-master-host"
  vpc_id = var.vpc_id
  tags = {
    App = "magento"
    Name = "magento-training-host"
    Environment =  var.environment
  }

  // allows traffic using ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

    // outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2magentohost" {
  instance_type     = "t2.medium"
  ami               = "ami-043cff825134b5508"
  subnet_id         = var.subnet_id
  vpc_security_group_ids    = [aws_security_group.magento_master.id]
  key_name          = var.key_name
  disable_api_termination = false
  ebs_optimized     = false
  root_block_device {
    volume_size = "10"
  }
  tags = {
    "App" = "magento"
    "Name" = "magento_master_instance"
    "Environment" = var.environment
  }
}