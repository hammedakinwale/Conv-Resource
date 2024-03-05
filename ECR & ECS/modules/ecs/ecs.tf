# create aws ecs cluster
resource "aws_ecs_cluster" "hammed_cluster" {
  name = var.hammed_cluster_name
}

# default vpc
resource "aws_default_vpc" "default_vpc" {}

# THREE DEFAULT SYBNETS FROM THREE DIFFERENT AZ

resource "aws_default_subnet" "default_subnet1" {
  availability_zone = var.availability_zones[0]
}

resource "aws_default_subnet" "default_subnet2" {
  availability_zone = var.availability_zones[1]
}

resource "aws_default_subnet" "default_subnet3" {
  availability_zone = var.availability_zones[2]
}

#  define task for the ecs
resource "aws_ecs_task_definition" "hammed_task" {
  family                   = var.hammed_task_famliy
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.hammed_task_name}",
      "image": "${var.ecr_repo_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${var.container_port},
          "hostPort": ${var.container_port}
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

# create aws iam role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# attach the iam role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# create load balancer
resource "aws_alb" "application_load_balancer" {
  name               = var.application_load_balancer_name
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet1.id}",
    "${aws_default_subnet.default_subnet2.id}",
    "${aws_default_subnet.default_subnet3.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# security group for the loadbalancer
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# target group for the load balancer
resource "aws_lb_target_group" "target_group" {
  name        = var.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id
}

# create load balancer listener and attach it to arn of the alb load balancer resource
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# aws ecs service
resource "aws_ecs_service" "hammed_service" {
  name            = var.hammed_service_name
  cluster         = aws_ecs_cluster.hammed_cluster.id
  task_definition = aws_ecs_task_definition.hammed_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.hammed_task.family
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet1.id}", "${aws_default_subnet.default_subnet2.id}", "${aws_default_subnet.default_subnet3.id}"]
    assign_public_ip = true
    security_groups  = ["${aws_security_group.service_security_group.id}"]
  }
}

#  reate service security group
resource "aws_security_group" "service_security_group" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}