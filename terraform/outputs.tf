# Output of the cluster ARN
output "cluster_arn" {
  value = aws_ecs_cluster.fargate_cluster.arn
}
# Output of the ecr repo ARN
output "ecr_repo_arn" {
  value = aws_ecr_repository.fargate_ecr_repository.arn
}

# Output of task ARN
output "task_arn" {
  value = aws_ecs_task_definition.ecr_task_definition.arn
}
