// logs configurations
resource "aws_cloudwatch_log_group" "ecs_exec_logs" {
  name              = "/aws/ecs/exec/${var.resource_tags["Project"]}-cluster"
  retention_in_days = 30

  tags = var.resource_tags
}


resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "/aws/ecs/${var.resource_tags["Project"]}-service"
  retention_in_days = 30

  tags = var.resource_tags
}

// cluster and capacity provider
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec_logs.name
        cloud_watch_encryption_enabled = true
      }
    }
  }

  region = var.region

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.resource_tags
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "${var.resource_tags["Project"]}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }

  depends_on = [
    aws_autoscaling_group.ecs_asg
  ]
}



// roles and attachements
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.resource_tags["Project"]}-ecs-instance-role"

  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.resource_tags["Project"]}-ecs-task-execution-role"

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

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.resource_tags["Project"]}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

// security groups
resource "aws_security_group" "ecs_instances_sg" {
  name        = "${var.resource_tags["Project"]}-ecs-instances-sg"
  description = "Security group for ECS container instances"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-ecs-instances-sg"
    }
  )
}

resource "aws_security_group" "ecs_alb_sg" {
  name        = "${var.resource_tags["Project"]}-ecs-alb-sg"
  description = "Allow HTTP/HTTPS traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-ecs-alb-sg"
    }
  )
}


resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.resource_tags["Project"]}-ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow ALB to reach ECS containers"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_alb_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.resource_tags
}

// launch template and auto scalling groups
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "${var.resource_tags["Project"]}-ecs-lt-"
  image_id      = var.instance_details.ami != "" ? var.instance_details.ami : data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_details.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_instances_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.resource_tags,
      {
        Name = "${var.resource_tags["Project"]}-ecs-instance"
      }
    )
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.resource_tags["Project"]}-ecs-asg"
  min_size                  = var.min_ec2_desired_capacity_for_asg
  max_size                  = var.max_ec2_desired_capacity_for_asg
  desired_capacity          = var.min_ec2_desired_capacity_for_asg
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.private_subnet_ids

  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.resource_tags["Project"]}-ecs-instance"
    propagate_at_launch = true
  }


  // to ensure proper cleanup
  force_delete = true
}


//task definitions
resource "aws_ecs_task_definition" "this" {
  for_each                 = var.services
  family                   = "${var.resource_tags["Project"]}-${each.key}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true

      portMappings = [
        {
          containerPort = each.value.port
          protocol      = "tcp"
        }
      ]

      environment = [
        for env_name, env_value in try(each.value.environment, {}) : {
          name  = env_name
          value = env_value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_task_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


// services
resource "aws_ecs_service" "this" {
  for_each        = var.services
  name            = "${var.resource_tags["Project"]}-${each.key}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets = var.private_subnet_ids

    security_groups = [
      aws_security_group.ecs_tasks_sg.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group[each.key].arn
    container_name   = each.key
    container_port   = each.value.port
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_cluster_capacity_providers
  ]
}


// Application load balancer
resource "aws_lb" "alb" {
  name               = "${var.resource_tags["Project"]}-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-ecs-alb"
    }
  )
}


// ALB target group
resource "aws_lb_target_group" "alb_target_group" {
  for_each = var.services

  name     = "${replace(each.key, "_", "-")}-tg"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  region      = var.region
  target_type = "ip"

  health_check {
    path                = each.value.health_check
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = var.resource_tags
}


// ALB Listener and rules
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching path"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "service_rules" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(keys(var.services), each.key)

  # Rewrite /backend or /frontend (and subpaths) to root path so targets receive /
  transform {
    type = "url-rewrite"
    url_rewrite_config {
      rewrite {
        regex   = "^/${each.key}/?(.*)"
        replace = "/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}*"]
    }
  }
}
