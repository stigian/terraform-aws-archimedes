data "aws_caller_identity" "default" {}

data "aws_region" "default" {}

resource "random_pet" "uuid" {}

resource "aws_s3_bucket" "logs" {
  bucket = "archimedes-logs-${random_pet.uuid.id}"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:project/${aws_codebuild_project.archimedes.name}",
      ]
    }
  }
}

resource "aws_iam_role" "default" {
  name               = "archimedes-runner-${random_pet.uuid.id}"
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

  statement {
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
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "default" {
  role   = aws_iam_role.default.name
  policy = data.aws_iam_policy_document.default.json
}

resource "aws_codebuild_project" "archimedes" {
  name          = "archimedes-runner-${random_pet.uuid.id}"
  description   = "GitHub Actions Runner for Archimedes"
  build_timeout = 60
  service_role  = aws_iam_role.default.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.logs.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    }
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
    type            = "GITHUB"
    location        = "https://github.com/mitchellh/packer.git"
    git_clone_depth = 1

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
