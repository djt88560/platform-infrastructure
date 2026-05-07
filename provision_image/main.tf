terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# Networking (default VPC)
# -----------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------
# Security Groups
# -----------------------------

# ALB security group
resource "aws_security_group" "alb_http" {
  name   = "alb-http"
  vpc_id = data.aws_vpc.default.id

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

# ECS task security group
resource "aws_security_group" "ecs_http" {
  name   = "ecs-http"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port                = 8000
    to_port                  = 8000
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb_http.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Application Load Balancer
# -----------------------------

resource "aws_lb" "alb" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_http.id]
}

resource "aws_lb_target_group" "app" {
  name        = "demo-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path    = "/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------
# ECS Cluster
# -----------------------------

resource "aws_ecs_cluster" "cluster" {
  name = "demo-cluster"
}

# -----------------------------
# IAM Role for ECS execution
# -----------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------
# ECS Task Definition
# -----------------------------

resource "aws_ecs_task_definition" "app" {
  family                   = "demo-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.image_url
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group = "ecs/app"
            awslogs-region = "us-east-1"
            awslogs-stream-prefix = "ecs"
          }
        }
    }
  ])
}

# -----------------------------
# ECS Service
# -----------------------------

resource "aws_ecs_service" "app" {
  name            = "demo-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_http.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}