# API Gateway Configuration
# Routes HTTP requests to ECS services via VPC Link and Cloud Map
# Production routes point to live slot, test routes point to idle slot

resource "aws_apigatewayv2_api" "main" {
  name          = "main-gateway"
  tags          = { Name = "main-gateway" }
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    max_age       = 300
  }
}

# Production integrations - point to live slot services via Cloud Map
resource "aws_apigatewayv2_integration" "services" {
  for_each = local.services

  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_service_discovery_service.services[each.key].arn

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.main.id
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "1.0"
  timeout_milliseconds   = each.value.timeout_milliseconds

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

# Test integrations - point to idle slot for testing deployments before going live
resource "aws_apigatewayv2_integration" "deployment_services" {
  for_each = local.services

  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_service_discovery_service.deployment_services[each.key].arn

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.main.id
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "1.0"
  timeout_milliseconds   = each.value.timeout_milliseconds

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

# Service discovery lookups
# Live slot used for production traffic, idle slot used for testing
data "aws_service_discovery_service" "services" {
  for_each = local.services

  name         = "${var.live_slot}-${each.key}"
  namespace_id = aws_service_discovery_private_dns_namespace.main.id

  depends_on = [aws_ecs_service.services]
}

data "aws_service_discovery_service" "deployment_services" {
  for_each = local.services

  name         = "${var.idle_slot}-${each.key}"
  namespace_id = aws_service_discovery_private_dns_namespace.main.id

  depends_on = [aws_ecs_service.services]
}

resource "aws_apigatewayv2_route" "test_services" {
  for_each = local.services

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /test/${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.deployment_services[each.key].id}"
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "main-vpc-link"
  tags               = { Name = "main-vpc-link" }
  subnet_ids         = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.gateway.id]
}

resource "aws_apigatewayv2_route" "services" {
  for_each = local.services

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.services[each.key].id}"
}

resource "aws_apigatewayv2_route" "options" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.services[keys(local.services)[0]].id}"
}

# =====================
# DEPLOYMENT
# =====================

resource "aws_apigatewayv2_deployment" "main" {
  api_id = aws_apigatewayv2_api.main.id

  triggers = {
    redeployment = sha1(jsonencode({
      integrations            = [for k, v in aws_apigatewayv2_integration.services : v.id]
      deployment_integrations = [for k, v in aws_apigatewayv2_integration.deployment_services : v.id]
      routes                  = [for k, v in aws_apigatewayv2_route.services : v.id]
      test_routes             = [for k, v in aws_apigatewayv2_route.test_services : v.id]
      options_route           = aws_apigatewayv2_route.options.id
      live_slot               = var.live_slot
      idle_slot               = var.idle_slot
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id        = aws_apigatewayv2_api.main.id
  tags          = { Name = "main-gateway-stage" }
  name          = "$default"
  deployment_id = aws_apigatewayv2_deployment.main.id

  # Note: auto_deploy is NOT used because we manage deployments via deployment_id
  # The deployment resource uses triggers to redeploy when routes/slots change
}
