# Create a VPC
resource "aws_vpc" "fingaurd" {
  cidr_block = var.vpc_cidr
}


#public subnet 1 
resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.fingaurd.id
  cidr_block = var.public_subnet_1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "fingaurd-pub-subnet-1"
  }
}

#public subnet 2
resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.fingaurd.id
  cidr_block = var.public_subnet_2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "fingaurd-pub-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "fingaurd_igw" {
  vpc_id = aws_vpc.fingaurd.id

  tags = {
    Name = "fingaurd-igw"
  }
}

# Public route table
resource "aws_route_table" "fingaurd_public" {
  vpc_id = aws_vpc.fingaurd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fingaurd_igw.id
  }

  tags = {
    Name = "fingaurd-public-route-table"
  }
}

# Subnet 1 route table association
resource "aws_route_table_association" "subnet_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.fingaurd_public.id
}

# Subnet 2 route table association
resource "aws_route_table_association" "subnet_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.fingaurd_public.id
}

#ecs cluster

resource "aws_ecs_cluster" "fingaurd_cluster" {
  name = "fin-cluster"
  
}

#task definetion the blue print of what to run

resource "aws_ecs_task_definition" "task_def_fingaurd" {
  family = "fingaurd_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.fargate_cpu
  memory = var.fargate_memory

  execution_role_arn = aws_iam_role.fingaurd_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fingaurd_container"
      image     = "717954157239.dkr.ecr.us-east-1.amazonaws.com/fingaurd_ecr:latest"
      cpu       = var.fargate_cpu
      memory    = var.fargate_memory
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = "/ecs/fingaurd-td"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])
}

# ecs service

resource "aws_ecs_service" "fingaurd_service" {
  name                = "fingaurd_service"
  cluster             = aws_ecs_cluster.fingaurd_cluster.id
  task_definition     = aws_ecs_task_definition.task_def_fingaurd.arn
  launch_type         = "FARGATE"
  desired_count       = 1

  network_configuration {
    subnets = [
      aws_subnet.subnet_1.id,
      aws_subnet.subnet_2.id
    ]

    security_groups = [
      aws_security_group.ecs_sg.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb-example.arn
    container_name   = "fingaurd_container"
    container_port   = 8000
  }
}

#ecs security groups 

resource "aws_security_group" "ecs_sg" {
  name        = "fingaurd-ecs-sg"
  description = "Security group for Fingaurd ECS tasks"
  vpc_id      = aws_vpc.fingaurd.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#ecr repo 

resource "aws_ecr_repository" "fingaurd_ecr" {
  name                 = "fingaurd_ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#applicatioin load balancer 

resource "aws_lb" "fingaurd_lb" {
  name               = "fingaurd-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
  
}

resource "aws_lb_listener" "fingaurd_http" {
  load_balancer_arn = aws_lb.fingaurd_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-example.arn
  }
}
#alb security groups

resource "aws_security_group" "lb_sg" {
  name        = "fingaurd-lb-sg"
  description = "Security group for Fingaurd ALB"
  vpc_id      = aws_vpc.fingaurd.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

# target groups 

resource "aws_lb_target_group" "alb-example" {
  name_prefix = "fing-"
  target_type = "ip"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fingaurd.id

  health_check {
    path = "/health"
    port = "8000"
  }
    lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "fingaurd.com"
#   validation_method = "DNS"

#   tags = {
#     Environment = "test"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Route 53 record
# resource "aws_route53_record" "tm" {
#   zone_id = aws_route53_zone.primary.zone_id
#   name    = "tm.yourdomain.com"
#   type    = "A"

#   alias {
#     name                   = aws_lb.fingaurd_lb.dns_name
#     zone_id                = aws_lb.fingaurd_lb.zone_id
#     evaluate_target_health = true
#   }
# }

#iamrole and polices

# ECS Task Execution Role
resource "aws_iam_role" "fingaurd_ecs_task_execution_role" {
  name = "fingaurd-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the standard ECS task execution policy
resource "aws_iam_role_policy_attachment" "fingaurd_ecs_task_execution_policy" {
  role = aws_iam_role.fingaurd_ecs_task_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}