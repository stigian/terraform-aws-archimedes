# variables brought in from module call

# name
variable "name" {
  description = "The name of the service"
  type        = string
}

#region
variable "aws_region" {
  description = "The AWS region where this infrastructure will be deployed."
  type        = string
  default     = "us-gov-west-1"
}

# container_name
variable "container_name" {
  description = "The name of the container"
  type        = string
}

# container_image
variable "container_image" {
  description = "The image of the container"
  type        = string
}

# container_port
variable "container_port" {
  description = "The port of the container"
  type        = number
}

# vpc_id
variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

# public_subnet_ids
variable "public_subnet_ids" {
  description = "The public subnet IDs"
  type        = list(string)
}

# # public_security_group_ids
# variable "public_security_group_ids" {
#   description = "The public security group IDs"
#   type        = list(string)
# }

# private_subnet_ids
variable "private_subnet_ids" {
  description = "The private subnet IDs"
  type        = list(string)
}

# # private_security_group_ids
# variable "private_security_group_ids" {
#   description = "The private security group IDs"
#   type        = list(string)
# }

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "env_var_1" {
  description = "Environment variable 1"
  type        = string
  default     = "default"
}

variable "target_group_arn" {
  description = "The ARN of the target group"
  type        = string
}