variable "aws_region" {
  type        = string
  default     = "us-gov-west-1"
  description = "The AWS region to deploy the CodeBuild project"
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = "The AWS account ID to deploy the CodeBuild project"
}
