// create aws ecs cluster and backing EC2 cluster capacity provider using asg
resource "aws_cloudwatch_log_group" "ecs_exec_logs" {
  name              = "/aws/ecs/exec/${var.resource_tags["Project"]}-cluster"
  retention_in_days = 30

  tags = var.resource_tags
}

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

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.resource_tags["Project"]}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_security_group" "ecs_instances_sg" {
  name        = "${var.resource_tags["Project"]}-ecs-instances-sg"
  description = "Security group for ECS container instances"
  vpc_id      = aws_vpc.main.id

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

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "${var.resource_tags["Project"]}-ecs-lt-"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_type

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
  min_size                  = var.instance_min_cap
  max_size                  = var.instance_max_cap
  desired_capacity          = var.instance_min_cap
  vpc_zone_identifier       = aws_subnet.public_subnet[*].id
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.resource_tags["Project"]}-ecs-instance"
    propagate_at_launch = true
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
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "/aws/ecs/${var.resource_tags["Project"]}-service"
  retention_in_days = 30

  tags = var.resource_tags
}

resource "aws_ecs_task_definition" "this" {
  for_each                 = var.services
  family                   = "${var.resource_tags["Project"]}-${each.key}"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = each.value.cpu
  memory                   = each.value.memory

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
          hostPort      = 0
          protocol      = "tcp"
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

resource "aws_ecs_service" "this" {
  for_each        = var.services
  name            = "${var.resource_tags["Project"]}-${each.key}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
    base              = 1
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_cluster_capacity_providers
  ]
}

