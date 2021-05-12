locals {
  common_prefix = "magento"
  elk_domain = "${local.common_prefix}-elk-domain"
}

resource "aws_security_group" "es" {
  name = "${local.common_prefix}-es-sg"
  description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
  vpc_id = var.vpc_id

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
  }
}

# resource "aws_iam_service_linked_role" "es" {
#   aws_service_name = "es.amazonaws.com"
# }

resource "aws_elasticsearch_domain" "es" {
  domain_name = local.elk_domain
  elasticsearch_version = "7.9"

  cluster_config {
      instance_count = 2

      instance_type = "t2.medium.elasticsearch"

      zone_awareness_enabled = true

      zone_awareness_config {
        availability_zone_count = 2
      }
  }

  vpc_options {
      subnet_ids = var.subnet_ids

      security_group_ids = [
          aws_security_group.es.id
      ]
  }

  ebs_options {
      ebs_enabled = true
      volume_size = 10
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:${var.region}:${var.account_id}:domain/${local.elk_domain}/*"
      }
  ]
}
CONFIG

  snapshot_options {
      automated_snapshot_start_hour = 23
  }

  tags = {
      Domain = local.elk_domain
      Environment = var.environment
  }
}

output "elk_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "elk_kibana_endpoint" {
  value = aws_elasticsearch_domain.es.kibana_endpoint
}