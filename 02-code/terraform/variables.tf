# Data sources for dynamic AWS environment information
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.region
  azs        = slice(data.aws_availability_zones.available.names, 0, 2)  # Use first 2 AZs
  account_id = data.aws_caller_identity.current.account_id
}

# Blue-Green Deployment Configuration
# Both slots share the same databases but have separate ECS services
# Switch traffic between slots by updating live_slot/idle_slot values

variable "live_slot" {
  type        = string
  description = "Which slot is currently live (blue or green)"
  default     = "blue"
}

variable "idle_slot" {
  type        = string
  description = "Which slot is currently idle (blue or green)"
  default     = "green"
}

# Service Configuration Defaults
# These values are merged with service-specific overrides from terraform.json

variable "service_defaults" {
  type = object({
    cpu                  = number
    memory               = number
    port                 = number
    scale                = number
    timeout_milliseconds = number
    log_retention        = number

    db_instance_class        = string
    db_engine                = string
    db_version               = string
    db_size_gb               = number
    db_max_size_gb           = number
    db_encrypted             = bool
    db_backup_retention_days = number
    db_backup_window         = string
    db_maintenance_window    = string
    db_username              = string
    db_passwd                = string

    dynamodb_key = string

    health_check_start_period_sec = number
    health_check_interval_sec     = number
    health_check_timeout_sec      = number
    health_check_retries          = number
  })
}

# Service definitions loaded from terraform.json and merged with defaults
locals {
  services_json = jsondecode(file("${path.module}/terraform.json"))

  services = {
    for key, config in local.services_json.services :
    key => merge(
      {
        cpu                  = var.service_defaults.cpu
        memory               = var.service_defaults.memory
        port                 = var.service_defaults.port
        scale                = var.service_defaults.scale
        timeout_milliseconds = var.service_defaults.timeout_milliseconds
        log_retention        = var.service_defaults.log_retention

        db_engine                = var.service_defaults.db_engine
        db_version               = var.service_defaults.db_version
        db_instance_class        = var.service_defaults.db_instance_class
        db_size_gb               = var.service_defaults.db_size_gb
        db_max_size_gb           = var.service_defaults.db_size_gb
        db_encrypted             = var.service_defaults.db_encrypted
        db_backup_retention_days = var.service_defaults.db_backup_retention_days
        db_backup_window         = var.service_defaults.db_backup_window
        db_maintenance_window    = var.service_defaults.db_maintenance_window
        db_username              = var.service_defaults.db_username
        db_passwd                = var.service_defaults.db_passwd

        dynamodb_key = var.service_defaults.dynamodb_key

        health_check_start_period_sec = var.service_defaults.health_check_start_period_sec
        health_check_interval_sec     = var.service_defaults.health_check_interval_sec
        health_check_timeout_sec      = var.service_defaults.health_check_timeout_sec
        health_check_retries          = var.service_defaults.health_check_retries
      },
      config,
      try(var.service_defaults[key], {})
    )
  }
}

variable "queue_defaults" {
  type = object({
    message_retention_seconds  = number
    polling_timeout_seconds    = number
    visibility_timeout_seconds = number
    max_receives               = number
  })
}

locals {
  queues_json = jsondecode(file("${path.module}/terraform.json"))

  queues = {
    for key, config in local.queues_json.queues :
    key => merge(
      {
        message_retention_seconds  = var.queue_defaults.message_retention_seconds
        polling_timeout_seconds    = var.queue_defaults.polling_timeout_seconds
        visibility_timeout_seconds = var.queue_defaults.visibility_timeout_seconds
        max_receives               = var.queue_defaults.max_receives
      },
      config,
      try(var.queue_defaults[key], {})
    )
  }
}

# Container image tags for each service
# Override these to deploy specific versions instead of 'latest'
variable "image_tags" {
  type    = map(string)
  default = {}
}

locals {
  default_image_tags = {
    for k, v in local.services : k => "latest"
  }

  image_tags = merge(local.default_image_tags, var.image_tags)
}
