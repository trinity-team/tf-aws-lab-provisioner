variable "name" {
  description = "Name to be used on all resources as prefix"
  type        = string
}

variable "instances_per_subnet" {
  description = "Number of windows and linux instances to launch per private subnet"
  type        = number
  default     = 1
}

variable "win_ami" {
  description = "ID of AMI to use for the windows instances"
  type        = string
}

variable "lin_ami" {
  description = "ID of AMI to use for the linux instances"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = ""
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "subnet_ids" {
  description = "List of private subnets to distribute instances across"
  type        = list(string)
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the devices created by the instance at launch time"
  type        = map(string)
  default     = {}
}

variable "use_num_suffix" {
  description = "Always append numerical suffix to instance name, even if instance_count is 1"
  type        = bool
  default     = false
}

variable "num_suffix_format" {
  description = "Numerical suffix format used as the volume and EC2 instance name suffix"
  type        = string
  default     = "-%d"
}



