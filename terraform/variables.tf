variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable "image_id" {
  description = "Disk image"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "service_account_key_file" {
  description = "key_tf.json"
}
variable "private_key_path" {
  description = "Path to the private ssh key"
}
variable region_id {
  description = "ID of the region that the application load balancer is located at"
  default     = "ru-central1"
}
variable count_of_instances {
  description = "Count of instances"
  default     = 1
}
