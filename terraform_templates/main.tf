# Define AWS provider and set the desired AWS region
provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create Subnets for High Availability
resource "aws_subnet" "subnet" {
  count = length(var.subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "subnet-${count.index}"
  }
}


# Route Table & Association
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-rtb"
  }
}

# Associate subnets with our route table
resource "aws_route_table_association" "main" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.main.id
}

# Security Group to Allow Ingress on Port 8000 and Egress
resource "aws_security_group" "ecs_tasks" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # consider restricting outbound access
  }

  ingress {
    from_port   = var.flask_app_port
    to_port     = var.flask_app_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ingress_cidr] # consider restricting inbound access
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}

# Define our ECS cluster
resource "aws_ecs_cluster" "echo_cluster" {
  name = var.ecs_cluster_name
}

# Create an IAM role for ECS execution
resource "aws_iam_role" "ecs_execution_role" {
  name = var.ecs_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

# Add permissions for ECR
resource "aws_iam_policy" "ecs_ecr_permissions" {
  name        = "ECS_ECR_Permissions"
  description = "ECS permissions to interact with ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"],
        Resource = "*"
      }
    ]
  })
}

# Attach the ECR permissions policy to our ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_ecr_permissions_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_ecr_permissions.arn
}

# Task definition for our ECS service
resource "aws_ecs_task_definition" "echo" {
  family                   = "echo"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions    = jsonencode([{
    name  = "echo"
    image = var.docker_image_url
    portMappings = [
      {
        containerPort = var.flask_app_port
        hostPort      = var.flask_app_port
      }
    ]
  }])
}


# ECS Service definition
resource "aws_ecs_service" "echo" {
  name            = "echo"
  cluster         = aws_ecs_cluster.echo_cluster.id
  task_definition = aws_ecs_task_definition.echo.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_task_count

  network_configuration {
    subnets          = aws_subnet.subnet.*.id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.echo_tg.arn
    container_name   = "echo"
    container_port   = var.flask_app_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "echo-service"
  }
}

# Add Autoscaling targets and policies after the ECS Service definition
## Autoscaling target for the ECS service
resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.echo_cluster.name}/${aws_ecs_service.echo.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 5
}

## Autoscaling policy to increase the desired count when CPU utilization exceeds 70%
resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.echo_cluster.name}/${aws_ecs_service.echo.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

## CloudWatch metric alarm to trigger the scaling policy based on CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = aws_ecs_cluster.echo_cluster.name
    ServiceName = aws_ecs_service.echo.name
  }

  alarm_description = "This metric triggers when CPU exceeds 70% for 2 periods of 60s"
  alarm_actions     = [aws_appautoscaling_policy.scale_up.arn]
}

#Security definitions for load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow inbound traffic on port 80"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Name = "lb-sg"
  }
}

# Load Balancer
resource "aws_lb" "echo_lb" {
  name               = "echo-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.subnet.*.id

  enable_deletion_protection = false

  tags = {
    Name = "echo-lb"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "echo_listener" {
  load_balancer_arn = aws_lb.echo_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.echo_tg.arn
  }
}

# Load Balancer Target Group
resource "aws_lb_target_group" "echo_tg" {
  name     = "echo-tg"
  target_type = "ip"
  port     = var.flask_app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}


resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_dashboard" "echo_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = templatefile("${path.module}/dashboard_template.json", {
    region      = var.aws_region,
    clusterName = var.ecs_cluster_name,
    serviceName = "echo"
  })
}

# Data sources to fetch AWS availability zones
data "aws_availability_zones" "available" {}
