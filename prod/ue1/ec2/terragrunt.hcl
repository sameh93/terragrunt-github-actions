
locals {
  env = yamldecode(file(find_in_parent_folders("env.yaml")))
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
  tags = {
    env = "${local.env.env_name}"
    region = "${local.region.region_id}"
    originated = "test terragrunt"
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
    public_subnets = ["temporary-dummy-id", "temporary-dummy-id"]
  }
}

dependency "sg" {
  config_path = "../sg"

  /*
  you cannot actually fetch outputs out of an unapplied Terraform module, even if there are no resources being created in the module.
  To address this, you can provide mock outputs to use when a module hasn’t been applied yet. This is configured using the mock_outputs
  */
  mock_outputs = {
    security_group_id = "temporary-dummy-id"
  }
}

terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=4.1.1"
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name                        = "test-from-terragrunt"
  ami                         = "ami-0cff7528ff583bf9a"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  subnet_id                   = element(dependency.vpc.outputs.public_subnets, 0)
  vpc_security_group_ids      = [dependency.sg.outputs.security_group_id]
  associate_public_ip_address = true

  tags = local.tags
}
