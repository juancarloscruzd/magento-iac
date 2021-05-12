output "efs_host" {
  value = aws_efs_file_system.magento-efs.dns_name
}

output "efs_mounts" {
  value = aws_efs_mount_target.magento-efs-mounts.*.dns_name
}

