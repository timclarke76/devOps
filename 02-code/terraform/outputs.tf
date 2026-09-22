output "gateway_url" {
  value = aws_apigatewayv2_stage.main.invoke_url
}

output "vue_app_bucket_name" {
  value = aws_s3_bucket.vue_app.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.vue_app.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.vue_app.domain_name
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.vue_app.domain_name}"
}

output "live_slot" {
  value = var.live_slot
}

output "idle_slot" {
  value = var.idle_slot
}
