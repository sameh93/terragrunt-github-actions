/*
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.5.0"

  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh"
    ]

    # With the get_terragrunt_dir() function, you can use relative paths!
    arguments = [
      "-var-file=${get_terragrunt_dir()}/../region.tfvars",
      "-var-file=${get_terragrunt_dir()}/../../env.tfvars"
    ]
  }
}

include "root" {
  path = find_in_parent_folders()
}
*/

locals {
  env = yamldecode(file(find_in_parent_folders("env.yaml")))
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
  tags = {
    env = "${local.env.env_name}"
    region = "${local.region.region_id}"
  }

  # load provider data from provider.hcl to generate it after that
  provider = read_terragrunt_config(find_in_parent_folders("provider.hcl"))
}

# Set the generate config dynamically to the generate config in provider.hcl
generate = local.provider.generate

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.5.0"
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.tags
}
