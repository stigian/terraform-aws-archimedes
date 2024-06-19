# Capture the AWS account number 
data "aws_caller_identity" "current" {}


# just the compute bits of the problem
# assume network and init has been completed 
# assume oidc is setup for this elsewhere
locals {
  # globals
  vpc_id             = "vpc-0c55c0f1db6679d0f"
  public_subnet_ids  = ["subnet-082dfec62679222ec", "subnet-0f0ede97c662f8a41"]
  private_subnet_ids = ["subnet-03b678625541d169b", "subnet-09650269ff485a20a"]
}

module "ecs-fargate-demo" {
  source = "./modules/ecs-fargate"

  name            = "archimedes"
  container_name  = "archimedes"
  container_image = "nginx:latest"
  container_port  = 80
  vpc_id          = local.vpc_id
  ## This is where the load balancer goes
  public_subnet_ids = local.public_subnet_ids
  #public_security_group_ids  = 
  # this is where the ecs task runs
  private_subnet_ids = local.private_subnet_ids
  #private_security_group_ids = 
  env_var_1        = "value1"
  target_group_arn = aws_lb_target_group.ecsfargate.arn
}


#stuff that gets created elsewhere
resource "aws_lb_target_group" "ecsfargate" {
  name        = "archimedes"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
}


#########################
### NLB for the web app 
#########################
resource "aws_lb" "ecsfargate" {
  name               = "app-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecsfargate.id] #Use IDs
  subnets            = local.public_subnet_ids
  tags = {
    Name = "app lb"
  }
}

resource "aws_security_group" "ecsfargate" {
  name        = "lb-ecsfargate-web"
  description = "ecsfargate container ingress on port 443"
  vpc_id      = local.vpc_id

  ingress {
    description = "Inbound port 443 to ecsfargate"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "No outbound restrictions"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_lb_listener" "ecsfargate_static_response" {
  load_balancer_arn = aws_lb.ecsfargate.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "LB is working"
      status_code  = "200"
    }
  }
}

resource "aws_alb_listener_rule" "ecsfargate_https" {
  listener_arn = aws_lb_listener.ecsfargate_static_response.arn
  #priority     = 100

  condition {
    host_header {
      values = [
        "archimedes.dod.cloud"
      ]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecsfargate.arn
  }

}