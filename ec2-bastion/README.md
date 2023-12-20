AWS EC2 BASTION 
================

This module creates a simple bastion server which can be used as a jump box to reach other AWS service, such as private RDS instances. It creates the following resources:

- An EC2 instance 
- An IAM role with the SSM Managed Instance Core policy 
- An instance profile



Inputs 
------

You must supply the following variables:

### Naming and tagging

* `name`: Name (kebab-case-format recommended) that will be used to prefix all resource names
* `tags`: Set of tags to be applied to all supported resources


### Configuration 
* `instance_type` : The family/size of instance to use, e.g. `t3.micro`

### Networking
* `public_subnet_id` : The ID of the public subnet to launch the instance into
* `security_group` : The ID of the security group to attach to the instance - **Ensure that this SG has outbound access, or SSM won't be able to connect!**
* `vpc_id` : The VPC to deploy the instance into

Example import
```terraform
    module ec2_bastion {
      source           = "../../../modules/ec2-bastion"
      instance_type    = "t3.micro"
      name             = "${var.env}-${var.project}"
      public_subnet_id = module.vpc.public_subnet_ids[0]
      security_group   = aws_security_group.rds_access.id
      tags             = local.default_tags
      vpc_id           = module.vpc.vpc_id
    }
```



Outputs 
----------
* `bastion_ip_address` : The public IP address of the newly created instance