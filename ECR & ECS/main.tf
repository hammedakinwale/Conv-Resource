terraform {
  required_version = "~> 1.3"

  # s3 backend block
  backend "s3" {
    bucket         = "hammed-tf-bname"
    key            = "tf-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hammed-Tf-tname"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# module for terraform state
module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = local.bucket_name
  table_name  = local.table_name
}

# mole for ecr repo
module "ecrRepo" {
  source = "./modules/ecr"

  ecr_repo_name = local.ecr_repo_name
}

# module for ecs cluster
module "ecsCluster" {
  source = "./modules/ecs"

  hammed_cluster_name = local.hammed_cluster_name
  availability_zones  = local.availability_zones

  hammed_task_famliy           = local.hammed_task_famliy
  ecr_repo_url                 = module.ecrRepo.repository_url
  container_port               = local.container_port
  hammed_task_name             = local.hammed_task_name
  ecs_task_execution_role_name = local.ecs_task_execution_role_name

  application_load_balancer_name = local.application_load_balancer_name
  target_group_name              = local.target_group_name
  hammed_service_name            = local.hammed_service_name
}