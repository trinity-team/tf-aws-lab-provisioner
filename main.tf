data "aws_ami" "ubuntu_18_04" {
  most_recent = true
  owners      = [var.ubuntu_account_number]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
data "aws_ami" "windows_server_2019" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [var.windows_account_number] # Canonical
}
data "aws_caller_identity" "current" {
}
module "prod_vpc" {
  source = ".//vpc"

  providers = {
    aws = aws.prod_region
  }

  name = "${var.customer_name}-prod"

  cidr = "10.0.0.0/16"

  azs             = ["${var.prod_region}a", "${var.prod_region}b", "${var.prod_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = merge(
    var.tags
  )
}
module "dr_vpc" {
  source = ".//vpc"

  providers = {
    aws = aws.dr_region
  }

  name = "${var.customer_name}-dr"

  cidr = "10.0.0.0/16"

  azs             = ["${var.dr_region}a", "${var.dr_region}b", "${var.dr_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = merge(
    var.tags
  )
}
module "jumpbox-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  name        = "jumpbox-access"
  description = "whitelists public IPs to jumpbox vms"
  vpc_id      = module.prod_vpc.vpc_id

  ingress_cidr_blocks = var.jumpbox_cidr_blocks
  ingress_rules       = ["https-443-tcp", "ssh-tcp", "rdp-tcp", "rdp-udp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]

  tags = merge(
    var.tags
  )
}
module "workload_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  name        = "workload-access"
  description = "whitelists jumpbox remote access and everything within sg"
  vpc_id      = module.prod_vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.jumpbox-sg.this_security_group_id
    },
    {
      rule                     = "rdp-tcp"
      source_security_group_id = module.jumpbox-sg.this_security_group_id
    },
    {
      rule                     = "rdp-udp"
      source_security_group_id = module.jumpbox-sg.this_security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.jumpbox-sg.this_security_group_id
    }
  ]

  number_of_computed_ingress_with_source_security_group_id = 4

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(
    var.tags
  )
}
module "ubnt-jb" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name  = "${var.customer_name}-ubnt-18-jb"
  count = 1

  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.jumpbox-sg.this_security_group_id]
  subnet_id              = module.prod_vpc.public_subnets[0]

  tags = merge(
    var.tags
  )
}
module "win-jb" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name  = "${var.customer_name}-win-2019-jb"
  count = 1

  ami                    = data.aws_ami.windows_server_2019.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.jumpbox-sg.this_security_group_id]
  subnet_id              = module.prod_vpc.public_subnets[0]

  tags = merge(
    var.tags
  )
}
module "instances" {
  source               = ".//ec2instances"
  name                 = var.customer_name
  instances_per_subnet = var.instances_per_subnet
  win_ami              = data.aws_ami.ubuntu_18_04.id
  lin_ami              = data.aws_ami.windows_server_2019.id
  instance_type        = var.instance_type
  subnet_ids           = module.prod_vpc.private_subnets
  tags = merge(
    var.tags
  )

  providers = {
    aws = aws.prod_region
  }

  depends_on = [
    module.prod_vpc
  ]

}
module "rds-mysql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "${var.customer_name}-rds-mysql"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = var.rds_instance_type
  allocated_storage = 5
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<r${var.customer_name}ion>:<account id>:key/<kms key id>"
  name     = "${var.customer_name}rdsmysql"
  username = "${var.customer_name}rdsuser"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "3306"

  vpc_security_group_ids = [module.workload_sg.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 0

  skip_final_snapshot = true

  tags = merge(
    var.tags
  )

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids = module.prod_vpc.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  #  options = [
  #    {
  #      option_name = "MARIADB_AUDIT_PLUGIN"
  #
  #      option_settings = [
  #        {
  #          name  = "SERVER_AUDIT_EVENTS"
  #          value = "CONNECT"
  #        },
  #        {
  #          name  = "SERVER_AUDIT_FILE_ROTATIONS"
  #          value = "37"
  #        },
  #      ]
  #    },
  #  ]
}
module "rds-postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "${var.customer_name}-rds-postgres"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "postgres"
  engine_version    = "9.6.9"
  instance_class    = var.rds_instance_type
  allocated_storage = 5
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<r${var.customer_name}ion>:<account id>:key/<kms key id>"
  name = "${var.customer_name}rdspostgres"
  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "${var.customer_name}rdsuser"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "5432"

  vpc_security_group_ids = [module.workload_sg.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 0

  skip_final_snapshot = true

  tags = merge(
    var.tags
  )

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = module.prod_vpc.private_subnets

  # DB parameter group
  family = "postgres9.6"

  # DB option group
  major_engine_version = "9.6"

  # Database Deletion Protection
  deletion_protection = false
}
module "rds-oracle" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "~> 2.0"
  identifier = "${var.customer_name}-rds-oracle"

  engine            = "oracle-ee"
  engine_version    = "12.1.0.2.v8"
  instance_class    = var.rds_instance_type
  allocated_storage = 10
  storage_encrypted = false
  license_model     = "bring-your-own-license"

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  name                                = "CVENORCL"
  username                            = "${var.customer_name}rdsuser"
  password                            = "YourPwdShouldBeLongAndSecure!"
  port                                = "1521"
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.workload_sg.this_security_group_id]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  skip_final_snapshot = true

  tags = merge(
    var.tags
  )

  # DB subnet group
  subnet_ids = module.prod_vpc.private_subnets
  multi_az   = true
  # DB parameter group
  family = "oracle-ee-12.1"

  # DB option group
  major_engine_version = "12.1"

  # See here for support character sets https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.OracleCharacterSets.html
  character_set_name = "AL32UTF8"

  # Database Deletion Protection
  deletion_protection = false
}
module "rds-mssql" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "~> 2.0"
  identifier = "${var.customer_name}-rds-mssql"

  engine            = "sqlserver-ex"
  engine_version    = "14.00.1000.169.v1"
  instance_class    = var.rds_instance_type
  allocated_storage = 20
  storage_encrypted = false

  name     = null
  username = "${var.customer_name}rdsuser"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "1433"

  #  domain               = aws_directory_service_directory.demo.id
  #  domain_iam_role_name = aws_iam_role.rds_ad_auth.name

  vpc_security_group_ids = [module.workload_sg.this_security_group_id]

  maintenance_window  = "Mon:00:00-Mon:03:00"
  backup_window       = "03:00-06:00"
  monitoring_interval = "60"
  monitoring_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/rds-monitoring-role"
  #create_monitoring_role = true

  # disable backups to create DB faster
  backup_retention_period = 0

  skip_final_snapshot = true

  tags = merge(
    var.tags
  )

  # DB subnet group
  subnet_ids = module.prod_vpc.private_subnets

  create_db_parameter_group = false
  license_model             = "license-included"

  timezone = "Eastern Standard Time"

  # Database Deletion Protection
  deletion_protection = false

  # DB options
  major_engine_version = "14.00"

  options = []
}