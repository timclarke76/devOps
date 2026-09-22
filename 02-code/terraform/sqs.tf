resource "aws_sqs_queue" "main" {
  for_each = local.queues

  name = "${each.key}-queue"
  tags = { Name = "${each.key}-queue" }

  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.polling_timeout_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
}

# Dead-letter queues
resource "aws_sqs_queue" "dlq" {
  for_each = local.queues

  name = "${each.key}-dlq"
  tags = { Name = "${each.key}-dlq" }

  message_retention_seconds = each.value.message_retention_seconds
}

resource "aws_sqs_queue_redrive_policy" "main" {
  for_each = local.queues

  queue_url = aws_sqs_queue.main[each.key].id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = each.value.max_receives
  })
}
