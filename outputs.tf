output "alb_dns_name" {
  description = "DNS name of the Fingaurd Application Load Balancer"
  value       = aws_lb.fingaurd_lb.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.fingaurd_cluster.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.fingaurd_ecr.repository_url
}