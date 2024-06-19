# Define the cluster
resource "aws_ecs_cluster" "ecsfargate" {
  name = "${local.name_ecs}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

# Create the cloudwatch log stream
resource "aws_cloudwatch_log_group" "ecsfargate" {
  name              = local.name_ecs
  retention_in_days = 365
}

# Security group for the container task
resource "aws_security_group" "ecsfargate_ecs" {
  name        = local.name_ecs
  description = "ecsfargate container ingress on port 80"
  vpc_id      = var.vpc_id

  ingress {
    description = "Inbound port ${var.container_port} to ecsfargate"
    protocol    = "tcp"
    from_port   = var.container_port
    to_port     = var.container_port
    self        = true
  }
  egress {
    description = "No outbound restrictions"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Create the assumerole for ECS to use when running the container
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create the task role, then build up the permissions on to it
resource "aws_iam_role" "ecsfargate_task_role" {
  name               = "${local.name_ecs}-ecsTaskRole"
  description        = "Fargate task role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = var.tags
}

# Create the task execution role and build up permissions
resource "aws_iam_role" "ecsfargate_task_execution_role" {
  name               = "${local.name_ecs}-ecsTaskExecutionRole"
  description        = "Fargate task execution role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecsfargate_task_execution" {
  role       = aws_iam_role.ecsfargate_task_execution_role.name
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
