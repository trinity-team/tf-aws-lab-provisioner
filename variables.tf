variable "customer_name" {
  default     = "oasislab"
  type        = string
  description = "customer name string used to generate lab resource names"
}
variable "instance_type" {
  default     = "m5.large"
  type        = string
  description = "type of instances to launch for this lab"
}
variable "rds_instance_type" {
  type    = string
  default = "db.t3.medium"
}
variable "ssh_key_name" {
  type    = string
  default = "tfkey"
}
variable "instances_per_subnet" {
  default     = 2
  type        = number
  description = "Number of Windows and Linux instances to create in each private subnet"

}
variable "prod_region" {
  default     = "us-west-2"
  type        = string
  description = "region to build prod vpc in"
}
variable "dr_region" {
  default     = "us-east-2"
  type        = string
  description = "region to build dr vpc in"
}
variable "tags" {
  type        = map
  description = "Default tags for infrastructure resources."
  default = {
    Owner = "oasis"
  }
}
variable "ubuntu_account_number" {
  default = "099720109477"
}
variable "windows_account_number" {
  default = "801119661308"
}
variable "jumpbox_cidr_blocks" {
  type        = list(string)
  description = "list of CIDR blocks allowed to connect to jumpbox"
}