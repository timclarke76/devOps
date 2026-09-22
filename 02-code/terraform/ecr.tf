# ECS Service Definitions and Blue-Green Deployment Configuration
# Creates both blue and green slots for each microservice (16 services total)

locals {
  # Create service-slot combinations for blue-green deployment
  # Results in 16 entries: auth-blue, auth-green, booking-blue, booking-green, etc.
  service_slots = merge([
    for slot in ["blue", "green"] : {
      for service_name, service_config in local.services :
      "${service_name}-${slot}" => {
        service = service_name
        slot    = slot
        config  = service_config
      }
    }
  ]...)
}

# Container registries - one per service (shared by both slots)
resource "aws_ecr_repository" "services" {
  for_each = local.services

  name         = each.key
  tags         = { Name = "${each.key}-ecr" }
  force_delete = true

  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
  tags = { Name = "main-cluster" }
}

# Task definitions for all service-slot combinations (16 total)
# Defines container configuration, resource limits, and environment variables
resource "aws_ecs_task_definition" "services" {
  for_each = local.service_slots

  family                   = "${each.value.slot}-${each.value.service}-task"
  tags                     = { Name = "${each.value.slot}-${each.value.service}-task" }
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.config.cpu
  memory                   = each.value.config.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "${each.value.slot}-${each.value.service}-service"
    image     = "${aws_ecr_repository.services[each.value.service].repository_url}:${local.image_tags[each.value.service]}"
    essential = true

    # Database credentials injected from Secrets Manager (except DynamoDB services)
    secrets = each.value.config.db_engine != null && each.value.config.db_engine != "dynamodb" ? [
      {
        name      = "DB_HOST"
        valueFrom = "${aws_secretsmanager_secret.db[each.value.service].arn}:host::"
      },
      {
        name      = "DB_PORT"
        valueFrom = "${aws_secretsmanager_secret.db[each.value.service].arn}:port::"
      },
      {
        name      = "DB_USER"
        valueFrom = "${aws_secretsmanager_secret.db[each.value.service].arn}:username::"
      },
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db[each.value.service].arn}:password::"
      },
      {
        name      = "DB_NAME"
        valueFrom = "${aws_secretsmanager_secret.db[each.value.service].arn}:dbname::"
      }
    ] : []

    environment = concat(
      [
        { name = "SERVICE_NAME", value = each.value.service }
      ],
      [
        for k, v in local.queues :
        { name = "${upper(k)}_QUEUE", value = aws_sqs_queue.main[k].url }
      ],
      [
        for k, v in local.services :
        {
          name  = "${upper(k)}_SERVICE_ENDPOINT",
          value = "${k}-${each.value.slot}.service-connect:${v.port}"
        }
      ]
    )

    portMappings = [{
      name          = "${each.value.service}-port"
      containerPort = each.value.config.port
      hostPort      = each.value.config.port
    }]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${each.value.config.port}/health || exit 1"]
      startPeriod = each.value.config.health_check_start_period_sec
      interval    = each.value.config.health_check_interval_sec
      timeout     = each.value.config.health_check_timeout_sec
      retries     = each.value.config.health_check_retries
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = local.region
        "awslogs-group"         = "/ecs/${each.value.slot}-${each.value.service}-service"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "services" {
  for_each = local.service_slots

  name                   = "${each.value.service}-${each.value.slot}-service"
  tags                   = { Name = "${each.value.slot}-${each.value.service}-service" }
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.services[each.key].arn
  desired_count          = each.value.config.scale
  launch_type            = "FARGATE"
  enable_execute_command = false

  network_configuration {
    security_groups = [aws_security_group.services.id]
    subnets         = [for s in aws_subnet.private : s.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.main.arn

    service {
      port_name             = "${each.value.service}-port"
      discovery_name        = "${each.value.slot}-${each.value.service}"
      ingress_port_override = 0

      client_alias {
        port     = each.value.config.port
        dns_name = "${each.value.service}-${each.value.slot}.service-connect"
      }
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    replace_triggered_by = [
      aws_service_discovery_private_dns_namespace.main.id
    ]

    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  depends_on = [aws_service_discovery_private_dns_namespace.main]
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "service-connect"
  tags = { Name = "service-connect" }
  vpc  = aws_vpc.gateway.id
}

resource "aws_cloudwatch_log_group" "services" {
  for_each = local.service_slots

  name              = "/ecs/${each.value.slot}-${each.value.service}-service"
  tags              = { Name = "${each.value.slot}-${each.value.service}-service-logs" }
  retention_in_days = each.value.config.log_retention
}
