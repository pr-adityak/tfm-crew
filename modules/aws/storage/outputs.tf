output "s3_data_bucket_name" {
  description = "Name of the primary data S3 bucket."
  value       = aws_s3_bucket.data.bucket
}

output "s3_data_bucket_arn" {
  description = "ARN of the primary data S3 bucket."
  value       = aws_s3_bucket.data.arn
}

output "s3_logs_bucket_name" {
  description = "Name of the logs S3 bucket."
  value       = aws_s3_bucket.logs.bucket
}

output "s3_logs_bucket_arn" {
  description = "ARN of the logs S3 bucket."
  value       = aws_s3_bucket.logs.arn
}
