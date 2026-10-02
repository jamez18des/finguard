variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "name of my project"
  type        = string
  default     = "finguard"
}

variable "vpc_cidr" {
  description = "defines the ip range for vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "container_port" {
  description = "the port that fingaurd is using"
  type        = number
  default     = 8000
}

variable "fargate_cpu" {
  description = "CPU allocated to the Fargate task"
  type        = number
  default     = 1024
}

variable "fargate_memory" {
  description = "Memory allocated to the Fargate task"
  type        = number
  default     = 3072
}

variable "desired_count" {
  description = "Number of Fargate tasks to run"
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Domain name used for the application"
  type        = string
}