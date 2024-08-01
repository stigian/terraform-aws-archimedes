data "aws_caller_identity" "default" {}

data "aws_region" "default" {}

resource "random_pet" "uuid" {}

resource "aws_s3_bucket" "logs" {
  bucket        = local.repo_name_lowercase
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_s3_bucket_lifecycle_configuration" "default" {
#   count  = module.this.enabled && local.create_s3_cache_bucket ? 1 : 0
#   bucket = join("", resource.aws_s3_bucket.cache_bucket[*].id)

#   rule {
#     id     = "codebuildcache"
#     status = "Enabled"

#     filter {
#       prefix = "/"
#     }

#     expiration {
#       days = var.cache_expiration_days
#     }
#   }
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# resource "aws_s3_bucket_logging" "default" {
#   count  = module.this.enabled && local.create_s3_cache_bucket && var.access_log_bucket_name != "" ? 1 : 0
#   bucket = join("", resource.aws_s3_bucket.cache_bucket[*].id)

#   target_bucket = var.access_log_bucket_name
#   target_prefix = "logs/${module.this.id}/"
# }

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceArn"
    #   values = [
    #     "arn:aws-us-gov:codebuild:${var.aws_region}:${var.aws_account_id}:project/${local.resource_name}",
    #   ]
    # }
  }
}

resource "aws_iam_role" "default" {
  name               = "archimedes-runner-${local.repo_name_lowercase}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "default" {
  statement { # CloudWatch permissions
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement { # VPC permissions
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  # statement {
  #   effect    = "Allow"
  #   actions   = ["ec2:CreateNetworkInterfacePermission"]
  #   resources = ["arn:aws-us-gov:ec2:${var.aws_region}:${var.aws_account_id}:network-interface/*"]

  #   condition {
  #     test     = "StringEquals"
  #     variable = "ec2:Subnet"

  #     values = [
  #       aws_subnet.example1.arn,
  #       aws_subnet.example2.arn,
  #     ]
  #   }

  #   condition {
  #     test     = "StringEquals"
  #     variable = "ec2:AuthorizedService"
  #     values   = ["codebuild.amazonaws.com"]
  #   }
  # }

  statement { # S3 permissions
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }

  statement { # ECR permissions
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
    resources = ["*"]
  }

  statement { # SSM Parameter Store
    effect = "Allow"
    actions = [
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:PutParameter"
    ]
    resources = ["arn:aws-us-gov:ssm:${var.aws_region}:${var.aws_account_id}:parameter/*"]
  }

  statement { # Secrets Manager
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["arn:aws-us-gov:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:*"]
  }
}

resource "aws_iam_role_policy" "default" {
  name   = "archimedes-runner-${local.repo_name_lowercase}"
  role   = aws_iam_role.default.name
  policy = data.aws_iam_policy_document.default.json
}

resource "aws_codebuild_project" "archimedes" {
  name                   = local.repo_name_lowercase
  description            = "GitHub Actions Runner for Archimedes"
  build_timeout          = var.build_timeout
  service_role           = aws_iam_role.default.arn
  concurrent_build_limit = var.concurrent_build_limit

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.logs.bucket
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    type                        = var.build_type
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
      type  = "PLAINTEXT"
    }

    # environment_variable {
    #   name  = "SOME_KEY2"
    #   value = "SOME_VALUE2"
    #   type  = "PARAMETER_STORE"
    # }

    # environment_variable {
    #   name  = "SOME_KEY3"
    #   value = "SOME_VALUE3"
    #   type  = "SECRETS_MANAGER"
    # }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "archimedes-group"
      stream_name = "archimedes-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.logs.id}/build-log"
    }
  }

  source {
    type                = var.source_type
    location            = var.source_location
    git_clone_depth     = 1
    insecure_ssl        = false
    report_build_status = true

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "main"

  # vpc_config {
  #   vpc_id = aws_vpc.example.id

  #   subnets = [
  #     aws_subnet.example1.id,
  #     aws_subnet.example2.id,
  #   ]

  #   security_group_ids = [
  #     aws_security_group.example1.id,
  #     aws_security_group.example2.id,
  #   ]
  # }

  tags = {
    Environment = "Test"
  }
}

resource "aws_codebuild_source_credential" "this" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = var.source_credential_server_type
  token       = var.source_credential_token
}


# resource "aws_codebuild_project" "project-with-cache" {
#   name           = "test-project-cache"
#   description    = "test_codebuild_project_cache"
#   build_timeout  = 5
#   queued_timeout = 5

#   service_role = aws_iam_role.example.arn

#   artifacts {
#     type = "NO_ARTIFACTS"
#   }

#   cache {
#     type  = "LOCAL"
#     modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
#   }

#   environment {
#     compute_type                = "BUILD_GENERAL1_SMALL"
#     image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
#     type                        = "LINUX_CONTAINER"
#     image_pull_credentials_type = "CODEBUILD"

#     environment_variable {
#       name  = "SOME_KEY1"
#       value = "SOME_VALUE1"
#     }
#   }

#   source {
#     type            = "GITHUB"
#     location        = "https://github.com/mitchellh/packer.git"
#     git_clone_depth = 1
#   }

#   tags = {
#     Environment = "Test"
#   }
# }

resource "aws_codebuild_webhook" "this" {
  project_name = aws_codebuild_project.archimedes.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

# resource "github_repository_webhook" "this" {
#   repository = var.source_location
#   active     = true
#   events     = ["push"]

#   configuration {
#     url          = aws_codebuild_webhook.archimedes.payload_url
#     secret       = aws_codebuild_webhook.archimedes.secret
#     content_type = "json"
#     insecure_ssl = false
#   }
# }
