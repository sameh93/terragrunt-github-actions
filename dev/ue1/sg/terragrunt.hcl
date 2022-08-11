
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

dependency "vpc" {
  config_path = "../vpc"

  /*
  you cannot actually fetch outputs out of an unapplied Terraform module, even if there are no resources being created in the module.
  To address this, you can provide mock outputs to use when a module hasn’t been applied yet. This is configured using the mock_outputs
  */
  mock_outputs = {
    vpc_id = "temporary-dummy-id"
  }
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=4.9.0"
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name        = "test-from-terragrunt-sg"
  description = "Security group which is used as an argument in complete-sg"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_rules       = ["https-443-tcp"]

  tags = local.tags
}
