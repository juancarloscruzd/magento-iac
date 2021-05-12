data "aws_ami" "base_image" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["magento*"]
  }
  
}

resource "aws_launch_template" "ec2lt" {
  name = "magentoweb"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  disable_api_termination = false
  image_id                = data.aws_ami.base_image.id
  instance_type           = "t2.small"
  key_name                = var.key_name
  vpc_security_group_ids  = [aws_security_group.sg-ELB-EC2.id]

  user_data = base64encode(data.template_file.userdata.rendered)

  tags = {
    App         = var.app_name
    Terraform   = "true"
    Environment = var.environment
    role        = "node"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "magento"
      App         = var.app_name
      Terraform   = "true"
      Environment = var.environment
      role        = "node"
    }
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.tmpl")

  vars = {
    efs_host = var.efs_host
  }
}

resource "aws_autoscaling_group" "asg" {
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.public_subnets
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1

  launch_template {
    id      = aws_launch_template.ec2lt.id
    version = "$Latest"
  }

  tags = [
    {
      App                 = var.app_name
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
    {
      App                 = var.app_name
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "asgpolicy" {
  name                   = "magento Web ASG Policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 360
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_security_group" "sg-ELBInbound" {
  name   = "magento - ELB In - Web"
  vpc_id = var.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_security_group" "sg-ELB-EC2" {
  name   = "magento - ELB to EC2"
  vpc_id = var.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    security_groups = [aws_security_group.sg-ELBInbound.id]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_alb" "webelb" {
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.sg-ELBInbound.id]
  name               = "externalmagentolb"
  internal           = false

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "webelb_tg" {
  port     = "80"
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/pub/health_check.php"
    port                = "80"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "webelb_listener_rule" {
  depends_on   = [aws_alb_target_group.webelb_tg]
  listener_arn = aws_alb_listener.webelb_httpin.arn
  priority     = "10"

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webelb_tg.id
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_autoscaling_attachment" "webelb_tg_attach" {
  alb_target_group_arn   = aws_alb_target_group.webelb_tg.arn
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_alb_listener" "webelb_httpin" {
  load_balancer_arn = aws_alb.webelb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.webelb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "webelb_httpsin" {
  load_balancer_arn = aws_alb.webelb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:398059953090:certificate/9561b0d6-4f15-4d00-a0ed-ddd18842aad3"

  default_action {
    target_group_arn = aws_alb_target_group.webelb_tg.arn
    type             = "forward"
  }
}

# Sadly we manage the domain on another account, so we need to improve this piece
// data "aws_route53_zone" "nextamazingsite_zone" {
//   name = var.dns_root
// }

// resource "aws_route53_record" "www" {
//   zone_id = data.aws_route53_zone.nextamazingsite_zone.zone_id
//   name    = var.dns_root
//   type    = "A"

//   alias {
//     name                   = aws_alb.webelb.dns_name
//     zone_id                = aws_alb.webelb.zone_id
//     evaluate_target_health = true
//   }
// }

