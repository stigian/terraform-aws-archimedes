# Hardcoded region for now, but we will change this later.
variable "region" {
  description = "The AWS region where this infrastructure will be deployed."
  type        = string
  default     = "us-gov-west-1"
}
