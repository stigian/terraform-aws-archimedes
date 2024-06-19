## A module which takes inputs and creates an ECS Fargate service with a load balancer

# Inputs include:
# - name: The name of the service
# - container_name: The name of the container
# - container_image: The image of the container
# - container_port: The port of the container
# - vpc_id: The VPC ID
# - subnet_ids: The subnet IDs
# - env_var_1: An environment variable to pass to the container
# - target_group_arn: The ARN of the target group to attach to the load balancer

# determine how to handle port mappings in the container definition

# Creates:
# - ECS Cluster
# - ECS Task Definition
# - ECS Service
# - cloudwatch log group

locals {
  name_ecs = "${var.name}-ecs"
}


# The task definition for the long-running ecsfargate service
resource "aws_ecs_task_definition" "ecsfargate" {
  family                   = "${local.name_ecs}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = local.service_template_ecsfargate
  task_role_arn            = aws_iam_role.ecsfargate_task_role.arn
  execution_role_arn       = aws_iam_role.ecsfargate_task_execution_role.arn
  cpu                      = 2048
  memory                   = 4096

  tags = var.tags
}

# The ECS service for the long-running ecsfargate container
resource "aws_ecs_service" "ecsfargate" {
  #checkov:skip=CKV_AWS_332:Platform Version 1.4.0 is the same at LATEST for now
  name             = "${local.name_ecs}-service"
  platform_version = "1.4.0"
  cluster          = aws_ecs_cluster.ecsfargate.id
  task_definition  = aws_ecs_task_definition.ecsfargate.arn
  desired_count    = 1
  launch_type      = "FARGATE"

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.name_ecs
    container_port   = var.container_port
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [
      aws_security_group.ecsfargate_ecs.id
    ]
  }

  tags = var.tags
}

# Set up the container definition for the ECS service
locals {
  service_template_ecsfargate = templatefile("${path.module}/files/service_container_definitions.json", {
    # Core Container Configuration
    name           = local.name_ecs
    image          = var.container_image
    log_group      = aws_cloudwatch_log_group.ecsfargate.name
    logs_region    = var.aws_region
    log_prefix     = var.name
    container_port = tonumber(var.container_port)
    env_var_1      = var.env_var_1
    }
  )
}
