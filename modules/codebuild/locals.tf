locals {
  # Split the URL by '/'
  split_url = split("/", var.source_location)

  # Get the last element of the list
  repo_name = local.split_url[length(local.split_url) - 1]

  cache_bucket_name = "${local.repo_name}-${var.cache_bucket_suffix_enabled ? "-${join("", random_string.bucket_prefix[*].result)}" : ""}"

  ## Clean up the bucket name to use only hyphens, and trim its length to 63 characters.
  ## As per https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
  cache_bucket_name_normalised = substr(
    join("-", split("_", lower(local.cache_bucket_name))),
    0,
    min(length(local.cache_bucket_name), 63),
  )

  s3_cache_enabled       = var.cache_type == "S3"
  create_s3_cache_bucket = local.s3_cache_enabled && var.s3_cache_bucket_name == null
  s3_bucket_name         = local.create_s3_cache_bucket ? join("", aws_s3_bucket.cache_bucket[*].bucket) : var.s3_cache_bucket_name

  aws_region     = signum(length(var.aws_region)) == 1 ? var.aws_region : data.aws_region.default.name
  aws_account_id = signum(length(var.aws_account_id)) == 1 ? var.aws_account_id : data.aws_caller_identity.default.account_id

  ## This is the magic where a map of a list of maps is generated
  ## and used to conditionally add the cache bucket option to the
  ## aws_codebuild_project
  cache_options = {
    "S3" = {
      type     = "S3"
      location = local.s3_cache_enabled ? local.s3_bucket_name : "none"
    },
    "LOCAL" = {
      type  = "LOCAL"
      modes = var.local_cache_modes
    },
    "NO_CACHE" = {
      type = "NO_CACHE"
    }
  }

  # Final Map Selected from above
  cache = local.cache_options[var.cache_type]
}
