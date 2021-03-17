resource "aws_instance" "windows" {
  count                  = var.instances_per_subnet * length(var.subnet_ids) #launch enough windows instances to to have var.instances_per_subnet instances in each of var.subnet_id[x]
  ami                    = var.win_ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    encrypted   = true
    volume_size = 50
    volume_type = "gp3"
  }
  tags = merge(
    {
      "Name" = var.instances_per_subnet > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", "${var.name}-win", count.index + 1) : var.name
    },
    var.tags,
  )
  volume_tags = merge(
    {
      "Name" = var.instances_per_subnet > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", "${var.name}-win", count.index + 1) : var.name
    },
    var.volume_tags,
  )
}

resource "aws_instance" "linux" {
  count                  = var.instances_per_subnet * length(var.subnet_ids) #launch enough linux instances to to have var.instances_per_subnet instances in each of var.subnet_id[x]
  ami                    = var.lin_ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    encrypted   = true
    volume_size = 50
    volume_type = "gp3"
  }
  tags = merge(
    {
      "Name" = var.instances_per_subnet > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", "${var.name}-lin", count.index + 1) : var.name
    },
    var.tags,
  )
  volume_tags = merge(
    {
      "Name" = var.instances_per_subnet > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", "${var.name}-lin", count.index + 1) : var.name
    },
    var.volume_tags,
  )
}

