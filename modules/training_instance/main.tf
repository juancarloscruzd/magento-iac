resource "aws_security_group" "magento_training" {

  name = "magento-training-host"
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
  ami               = "ami-03d77e33a505fde57" 
  subnet_id         = var.subnet_id
  vpc_security_group_ids    = [aws_security_group.magento_training.id]
  key_name          = var.key_name
  disable_api_termination = false
  ebs_optimized     = false
  root_block_device {
    volume_size = "10"
  }
  tags = {
    "App" = "magento"
    "Name" = "magento-training"
    "Environment" = var.environment
  }
}

resource "aws_eip" "bastionhost" {
  instance = aws_instance.ec2magentohost.id
  vpc = true
}