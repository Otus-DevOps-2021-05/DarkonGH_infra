variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable subnet_id {
description = "Subnets for modules"
}
variable core_fraction {
  description = "Core fraction for instance"
  type = number
  default = 20
}
variable cores {
  description = "Core number for instance"
  type = number
  default = 2
}
variable memory {
  description = "Memory GB for instance"
  type = number
  default = 2
}
variable name {
  description = "Instance name"
  type = string
  default = "reddit-app"
}
