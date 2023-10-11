variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "ap-south-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets"
}

variable "flask_app_port" {
  description = "The port the Flask app listens on"
}

variable "allowed_ingress_cidr" {
  description = "CIDR block that is allowed to access the Flask app"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  default     = "echo-cluster"
}

variable "ecs_execution_role_name" {
  description = "Name of the ECS execution role"
  default     = "ecs_execution_role"
}

variable "docker_image_url" {
  description = "URL of the Docker image for the Flask app"
}

variable "task_cpu" {
  description = "CPU value for the task"
}

variable "task_memory" {
  description = "Memory value for the task"
}

variable "desired_task_count" {
  description = "Number of desired tasks for the Flask service"
}

variable "subnet_count" {
  description = "determines the number of subnets you wish to create within your VPC. Typically, this value corresponds to how many availability zones (AZs) you want to deploy resources across for redundancy and high availability."
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  default     = "ecs-logs"
}

variable "log_retention_days" {
  description = "Retention period for logs in days"
}

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  default     = "Echo-Dashboard"
}
