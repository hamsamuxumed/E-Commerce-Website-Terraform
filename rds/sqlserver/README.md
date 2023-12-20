AWS RDS SQL Server
==================

This module creates an instance of Microsoft SQL Server in AWS RDS, and associated resources:

- A DB subnet group
- An options group that allows native backup and restore from an S3 bucket
- A security group that permits inbound access to instances in a specific security group
- A Secrets Manager secret containing all the connection information

The resource is configured with sensible defaults:

- A randomly-generated password
- Automatic minor version updates


Inputs
------

You must supply the following variables:

### Naming and tagging

* `name`: Name (kebab-case-format recommended) that will be used to prefix all resource names
* `tags`: Set of tags to be applied to all supported resources


### SQL Server configuration

* `edition`: the SQL Server edition. Possible values include:
  * `ex` - Express Edition (does not support Multi AZ)
  * `web` - Web Edition (does not support Multi AZ)
  * `se` - Standard Edition
  * `ee` - Enterprise Edition
* `engine_version`: the major version of the SQL Service engine. Possible values include:
  * `15.00` - SQL Server 2019
  * `14.00` - SQL Server 2017
  * `13.00` - SQL Server 2016
  * `12.00` - SQL Server 2014
  * `11.00` - SQL Server 2012
* `instance_class`: the instance type. Valid instance types depend on the edition and version of
  SQL Server. Refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html#SQLServer.Concepts.General.InstanceClasses


### Networking

* `subnets`: a list of subnet IDs that the database should be placed into. There must be at least
  one; or when HA is enabled, at least two.
* `access_security_group`: the ID of a security group whose instances should be allowed to access
  the RDS instance.


### Special configuration

* `override_names`: a map which defines the names of resources, overriding the default systematic
  names. This variable is optional, and it may contain zero or more overrides. Valid keys are:
  * `subnet_group`
  * `option_group`
  * `option_group_description`
  * `rds_security_group`
  * `rds_security_group_description`
  * `rds_instance`
  * `secrets_manager_secret_name`


Outputs
-------

None.
