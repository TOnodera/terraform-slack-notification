
/**
 * VPC
 */
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.application_name}-vpc"
  }
}

resource "aws_subnet" "public1a" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "${var.application_name}-subnet-public1"
  }
}

resource "aws_subnet" "public1c" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "${var.application_name}-subnet-public1"
  }
}

resource "aws_subnet" "private1a" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.3.0/24"
  tags = {
    Name = "${var.application_name}-subnet-private1a"
  }
}

resource "aws_subnet" "private1c" {

  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.4.0/24"
  tags = {
    Name = "${var.application_name}-subnet-private1c"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.application_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.application_name}-route-table"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
}

# サブネットとルートテーブルの紐づけ
resource "aws_route_table_association" "public1a" {
  subnet_id      = aws_subnet.public1a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public1c" {
  subnet_id      = aws_subnet.public1c.id
  route_table_id = aws_route_table.public.id
}

# NAT
resource "aws_eip" "nat_1a" {
  tags = {
    Name = "${var.application_name}-eip-1a"
  }
}

resource "aws_nat_gateway" "natgw_1a" {
  subnet_id     = aws_subnet.public1a.id
  allocation_id = aws_eip.nat_1a.id
  tags = {
    Name = "${var.application_name}-ngw-1a"
  }
}
resource "aws_eip" "nat_1c" {
  tags = {
    Name = "${var.application_name}-eip-1c"
  }
}

resource "aws_nat_gateway" "natgw_1c" {
  subnet_id     = aws_subnet.public1c.id
  allocation_id = aws_eip.nat_1c.id
  tags = {
    Name = "${var.application_name}-ngw-1c"
  }
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.application_name}-pvt-rtb-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.application_name}-pvt-rtb-1c"
  }
}

resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  gateway_id             = aws_nat_gateway.natgw_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  gateway_id             = aws_nat_gateway.natgw_1c.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private1c.id
  route_table_id = aws_route_table.private_1c.id
}


/**
 * ALB 
 */
resource "aws_security_group" "alb" {
  name   = "${var.application_name}-security-group-alb"
  vpc_id = aws_vpc.this.id
  # アウトバンドの許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  # 80番ポートへのアクセスを許可
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# ALB
resource "aws_lb" "this" {
  load_balancer_type = "application"
  name               = "${var.application_name}-alb"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1a.id, aws_subnet.public1c.id]
}

resource "aws_alb_listener" "this" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.this.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = 200
      message_body = "ok"
    }
  }
}

/**
 * ECS
 */
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_execution_role_policy" {
  name = "ecs-task-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_execution_role_policy.arn
  role       = aws_iam_role.ecs_task_role.name
}


resource "aws_ecr_repository" "terraformslack_notification" {
  name = "terraform_slack_notification"
}
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.application_name}-ecs-family"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  container_definitions    = <<EOL
[
    {
        "name": "terraform_slack_notification",
        "image": "${var.docker_image_in_ecr}",
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-region": "ap-northeast-1",
            "awslogs-group": "/ecs/terraform_slack_notification",
            "awslogs-stream-prefix": "tsn"
          }
        },
        "portMappings": [
            {
                "containerPort": 3000,
                "hostPort": 3000 
            }
        ]
    }
]
EOL
}

resource "aws_ecs_cluster" "this" {
  name = "${var.application_name}-ecs-cluster"
}

resource "aws_lb_target_group" "this" {
  name        = "${var.application_name}-tgp"
  vpc_id      = aws_vpc.this.id
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_alb_listener.this.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_security_group" "ecs" {
  name   = "${var.application_name}-sgr-ecs"
  vpc_id = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.application_name}-sgr-ecs"
  }
}

resource "aws_security_group_rule" "esc_sgr_rule" {
  security_group_id = aws_security_group.ecs.id
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}

resource "aws_ecs_service" "this" {
  name            = "${var.application_name}-ecs-service"
  depends_on      = [aws_lb_listener_rule.this]
  cluster         = aws_ecs_cluster.this.name
  desired_count   = 1
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.private1a.id, aws_subnet.private1c.id]
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "terraform_slack_notification"
    container_port   = 3000
  }
}

/*
 * CloudWatchLogs
 */
resource "aws_cloudwatch_log_group" "terraform_slack_notification" {
  name              = "/ecs/terraform_slack_notification"
  retention_in_days = 30
}

