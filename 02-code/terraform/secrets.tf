resource "aws_secretsmanager_secret" "db" {
  for_each = {
    for key, service in local.services : key => service
    if service.db_engine != null &&
    service.db_engine != "dynamodb"
  }

  name = "${aws_db_instance.db[each.key].db_name}-secrets"
  tags = { Name = "${aws_db_instance.db[each.key].db_name}-secrets" }
}

resource "aws_secretsmanager_secret_version" "db" {
  for_each = aws_secretsmanager_secret.db

  secret_id = each.value.id

  secret_string = jsonencode({
    username = local.services[each.key].db_username
    password = local.services[each.key].db_passwd
    host     = aws_db_instance.db[each.key].address
    port     = aws_db_instance.db[each.key].port
    dbname   = aws_db_instance.db[each.key].db_name
  })
}
