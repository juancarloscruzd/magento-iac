output "pem_file_name" {
  value = aws_key_pair.generated_key.key_name
}
