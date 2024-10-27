output "rds_public_address" {
  description = "The public address (endpoint) of the RDS instance"
  value       = aws_db_instance.my_db.endpoint  # Retrieves the public endpoint of the RDS instance
}