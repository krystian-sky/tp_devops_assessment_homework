# Create VPC for the Fargate Cluster
resource "aws_vpc" "fargate_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "fargate_igw" {
  vpc_id = aws_vpc.fargate_vpc.id
}

# Create Public Subnet
resource "aws_subnet" "fargate_public_subnet" {
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = local.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_route" "internet_route" {
  route_table_id         = data.aws_route_table.vpc_routing_table.id
  destination_cidr_block = var.internet_cidr_block
  gateway_id             = aws_internet_gateway.fargate_igw.id
}

# Create Security Group for Fargate Cluster
resource "aws_security_group" "fargate_sg" {
  name        = "fargate-cluster-sg"
  description = "Security group for the Fargate cluster"

  vpc_id = aws_vpc.fargate_vpc.id

  ingress {
    cidr_blocks = [var.internet_cidr_block]
    description = "From the internet"
    from_port   = 0
    protocol    = "tcp"
    to_port     = 65535
  }

  egress {
    cidr_blocks = [var.internet_cidr_block]
    description = "To the internet"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

# Create the Fargate Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = format("%s-fargate-cluster", var.name)
}

resource "aws_ecr_repository" "fargate_ecr_repository" {
  name = var.name
}

resource "aws_ecs_task_definition" "ecr_task_definition" {
  #   family                   = "krystian-nowaczyk-ecr-task"
  family                   = format("%s-ecr-task", var.name)
  execution_role_arn       = var.ecs_role
  task_role_arn            = var.ecs_role
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<EOF
[
  {
    "name": "my-container",
    "image": "${aws_ecr_repository.fargate_ecr_repository.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": 5000,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/my-ecr-task",
        "awslogs-region": "eu-north-1",
        "awslogs-stream-prefix": "my-ecr-task"
      }
    }
  }
]
EOF

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "ecr_service" {
  name            = format("%s-service", var.name)
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.ecr_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"



  network_configuration {
    subnets          = [aws_subnet.fargate_public_subnet.id]
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_target_group.arn
    container_name = "my-container"
    container_port = 5000
  }
}


resource "aws_elb" "fargate_elb" {
  name            = "fargate-elb"
  subnets         = [aws_subnet.fargate_public_subnet.id]
  security_groups = [aws_security_group.fargate_sg.id]


  listener {
    instance_port     = 5000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:5000/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }


}

resource "aws_lb_target_group" "fargate_target_group" {
  name     = "fargate-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.fargate_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
    port = 5000
  }

}