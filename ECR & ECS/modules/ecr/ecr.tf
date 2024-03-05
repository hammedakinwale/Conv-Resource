# aws ecr repository
resource "aws_ecr_repository" "hammed_ecr_repo" {
  name = var.ecr_repo_name
}
