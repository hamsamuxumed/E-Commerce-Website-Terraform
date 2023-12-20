EFS Volume module for Terraform
===============================

This module creates an EFS volume and associated resources:

- A security group which restricts access only to sources that have a specific security group
- Mount targets in each subnet

The resource is configured with sensible defaults:

- The EFS volume is encrypted at rest, using the KMS key with the alias `aws/elasticfilesystem`
- The EFS volume is using general purpose performance mode, and bursting throughput mode
- The security group allows TCP port 2049 inbound from only the security group given as an input


Inputs
------

You must supply the following variables:

### Naming and tagging

name
: Name (kebab-case-format recommended) that will be used to prefix all resource names
tags
: Set of tags to be applied to all supported resources

### Network configuration

subnets
: List of AWS subnets to create a mount target in. Must all be in the same VPC.
access_security_group
: ID of a security group whose members can access the EFS volume

### Override names and descriptions

These allow you to override the systematic names of resources that do not support renaming. This
can be helpful when importing existing resources - a name change would cause Terraform to delete
and re-create resources, but by specifying these variables, you can avoid resources changing names.

override_security_group_name
: Explicit name for the security group, overriding the module's default name
override_security_group_description
: Explicit description for the security group, overriding the module's default description

Outputs
-------

efs_volume_id
: The ID of the new EFS volume. This can be used to attach the volume to an EC2 instance or a
  container.
