# Database Configuration
# RDS instances shared between blue and green slots

resource "aws_db_instance" "db" {
  for_each = {
    for key, service in local.services : key => service
    if service.db_engine != null &&
    service.db_engine != "dynamodb"
  }

  identifier            = "${each.key}-db"
  tags                  = { Name = "${each.key}-db" }
  instance_class        = each.value.db_instance_class
  engine                = each.value.db_engine
  engine_version        = each.value.db_version
  allocated_storage     = each.value.db_size_gb
  max_allocated_storage = each.value.db_max_size_gb
  storage_encrypted     = each.value.db_encrypted

  backup_retention_period = each.value.db_backup_retention_days
  backup_window           = each.value.db_backup_window
  maintenance_window      = each.value.db_maintenance_window

  db_name  = each.key
  username = each.value.db_username
  password = each.value.db_passwd

  skip_final_snapshot = true

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_dynamodb_table" "dynamodb" {
  for_each = {
    for key, service in local.services : key => service
    if service.db_engine == "dynamodb"
  }

  name         = "${each.key}-table"
  tags         = { Name = "${each.key}-dynamodb" }
  billing_mode = "PAY_PER_REQUEST"

  hash_key = each.value.dynamodb_key

  attribute {
    name = each.value.dynamodb_key
    type = "S"
  }

  attribute {
    name = "ServiceName"
    type = "S"
  }

  attribute {
    name = "Time"
    type = "S"
  }

  global_secondary_index {
    name            = "ServiceTimeIndex"
    hash_key        = "ServiceName"
    range_key       = "Time"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }
}
