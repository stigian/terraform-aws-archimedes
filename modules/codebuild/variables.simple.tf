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

variable "build_image" {
  type        = string
  default     = "aws/codebuild/standard:7.0"
  description = "Docker image for build environment, e.g. 'aws/codebuild/standard:7.0' or 'aws/codebuild/amazonlinux2-x86_64-standard:5.0'. For more info: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html"
}

variable "build_compute_type" {
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  description = "Instance type of the build instance"
}

variable "build_timeout" {
  default     = 60
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
}

variable "build_type" {
  type        = string
  default     = "LINUX_CONTAINER"
  description = "The type of build environment, e.g. 'LINUX_CONTAINER' or 'WINDOWS_CONTAINER'"
}

variable "concurrent_build_limit" {
  type        = number
  default     = 1
  description = "The number of concurrent builds allowed"
}

variable "source_credential_auth_type" {
  type        = string
  default     = "PERSONAL_ACCESS_TOKEN"
  description = "The type of authentication used to connect to a GitHub or GitHub Enterprise"
}

variable "source_credential_server_type" {
  type        = string
  default     = "GITHUB"
  description = "The source provider used for this project. Options are GITHUB or GITHUB_ENTERPRISE"
}

variable "source_credential_token" {
  type        = string
  default     = ""
  description = "For GitHub or GitHub Enterprise, this is the personal access token"
}

variable "source_location" {
  type        = string
  description = "The URL of the GitHub repo without the .git extension"
}

variable "source_type" {
  type        = string
  default     = "GITHUB"
  description = "The type of repository that contains the source code to be built. Valid values for this parameter are: CODECOMMIT, CODEPIPELINE, GITHUB, GITHUB_ENTERPRISE, or S3"
}
