# tf-aws-lab1-template

This module will produce the following resources for use in rubrik labs:
* 1 VPC with 3 public and 3 private subnets in the `prod_region`, assumes `a` `b` and `c` AZs are availabile in the specified region
* 1 VPC with 3 public and 3 private subnets in the `dr_region`, assumes `a` `b` and `c` AZs are availabile in the specified region
* 3*`instances_per_subnet` ubuntu instances, spread evenly across the 3 private subnets in `prod_region`
* 3*`instances_per_subnet` windows instances, spread evenly across the 3 private subnets in `prod_region`
* an ubuntu jumpbox in `public_subnet[0]` with SSH and RDP whitelisted inbound from `jumpbox_cidr_blocks`
* a windows jumpbox in `public_subnet[0]` with SSH and RDP whitelisted inbound from `jumpbox_cidr_blocks`
* 4 RDS instances (mysql, postgres, oracle, mssql) spread across the 3 private subnets in `prod_region`

Resource names are prepended with `customer_name`, ec2 instances are of type `instance_type` and rds instances are of type `rds_instance_type`. Instances will be accessible by using `ssh_key_name` and only the jumpboxes are internet facing. Resource tags can be specified with `tags`.
