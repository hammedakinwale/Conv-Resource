locals {
  bucket_name = "hammed-tf-bname"
  table_name  = "hammed-Tf-tname"

  ecr_repo_name = "hammed-ecr-repo"

  hammed_cluster_name          = "hammedp-cluster"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  hammed_task_famliy           = "hammed-task"
  container_port               = 3000
  hammed_task_name             = "hammed-task"
  ecs_task_execution_role_name = "hammed-task-execution-role"

  application_load_balancer_name = "hammed-app-alb"
  target_group_name              = "hammed-alb-tg"

  hammed_service_name = "hammed-app-service"
}