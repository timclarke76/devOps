service_defaults = {
  cpu                  = 256
  memory               = 512
  port                 = 8080
  scale                = 1
  timeout_milliseconds = 3000
  log_retention        = 1

  db_instance_class        = "db.t3.micro"
  db_engine                = "postgres"
  db_version               = "16.11"
  db_size_gb               = 20
  db_max_size_gb           = 100
  db_encrypted             = true
  db_backup_retention_days = 1
  db_backup_window         = "03:00-04:00"
  db_maintenance_window    = "sun:04:00-sun:05:00"
  db_username              = "postgres"
  db_passwd                = "BoadroomCollective123!"

  dynamodb_key = "ID"

  health_check_start_period_sec = 30
  health_check_interval_sec     = 30
  health_check_timeout_sec      = 5
  health_check_retries          = 5
}

queue_defaults = {
  message_retention_seconds  = 1209600
  polling_timeout_seconds    = 10
  visibility_timeout_seconds = 30
  max_receives               = 5
}
