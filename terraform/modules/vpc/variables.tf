variable network_name {
  description = "Network name"
  default = "reddit-app-network"
}

variable subnet_name {
  description = "Subnet name"
  default = "reddit-app-subnet"
}

variable zone {
  description = "Subnet zone"
  default = "ru-central1-a"
}

variable cidr {
  description = "Subnet CIDR"
  default = "192.168.10.0/24"
}
