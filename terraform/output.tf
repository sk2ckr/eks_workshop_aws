output "repository_url" {
  description = "ECR repository URL of Docker image"
  value       = aws_ecr_repository.repo.repository_url
}

output "tag" {
  description = "Docker image tag"
  value       = var.tag
}

output "hash" {
  description = "Docker image source hash"
  value       = data.external.hash.result["hash"]
}

/*
output "BuildTrustRoleOutput" {
    value = aws_iam_role.BuildTrustRole.id
}

output "DeployTrustRoleOutput" {
    value = aws_iam_role.DeployTrustRole.id
}

output "PipelineTrustRoleOutput" {
    value = aws_iam_role.PipelineTrustRole.id
}

output "CodePipelineLambdaExecRoleOutput" {
    value = aws_iam_role.CodePipelineLambdaExecRole.id
}

output "S3BucketName" {
    value = aws_s3_bucket.S3Bucket.id
}
*/