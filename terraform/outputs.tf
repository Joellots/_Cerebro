output "runner_id" {
  description = "Runner ID"
  value       = aws_instance.runner.id
}

output "runner_public_ip" {
  description = "Runner IP (public)"
  value       = aws_instance.runner.public_ip
}

output "runner_dns" {
  description = "Runner DNS"
  value       = aws_instance.runner.public_dns
}

output "runner_private_ip" {
  description = "Runner Internal IP"
  value       = aws_instance.runner.private_ip
}


