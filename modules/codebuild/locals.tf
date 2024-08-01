locals {
  # Split the URL by '/'
  split_url = split("/", var.source_location)

  # Get the last element of the list
  repo_name = local.split_url[length(local.split_url) - 1]

  # Convert the extracted name to lowercase
  repo_name_lowercase = lower(local.repo_name)
}
