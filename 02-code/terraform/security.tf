resource "aws_security_group" "gateway" {
  name   = "gateway-sg"
  tags   = { Name = "gateway-sg" }
  vpc_id = aws_vpc.gateway.id

  dynamic "egress" {
    for_each = distinct([for k, v in local.services : v.port])
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = [for s in aws_subnet.private : s.cidr_block]
      description = "to: services"
    }
  }
}

resource "aws_security_group" "services" {
  name   = "services-sg"
  tags   = { Name = "services-sg" }
  vpc_id = aws_vpc.gateway.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "from: AWS"
  }

  dynamic "ingress" {
    for_each = distinct([for k, v in local.services : v.port])
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.gateway.id]
      description     = "from: gateway"
    }
  }

  dynamic "ingress" {
    for_each = distinct([for k, v in local.services : v.port])
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      self        = true
      description = "service-to-service communication"
    }
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "to: AWS"
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for s in aws_subnet.private : s.cidr_block]
    description = "to: database"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all internal service-to-service egress"
  }
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  tags   = { Name = "db-sg" }
  vpc_id = aws_vpc.gateway.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.services.id]
    description     = "from: services"
  }
}
