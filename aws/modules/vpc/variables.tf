variable "cidr" {
  description = "VPC cidr block. Example: 10.0.0.0/16"
}

variable "environment" {
  description = "The name of the environment"
}

variable "aws_email" {
  description = "the user email address"
}

variable "name" {
  description = "prefix for all created resources"
}
