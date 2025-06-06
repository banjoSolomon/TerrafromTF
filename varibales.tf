# variables.tf

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}
