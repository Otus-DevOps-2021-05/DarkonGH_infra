resource "yandex_compute_instance" "db" {
  name = var.name
  allow_stopping_for_update = true
  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = var.cores
    memory = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  # connection {
  #  type  = "ssh"
  #  host  = yandex_compute_instance.db.network_interface.0.nat_ip_address
  #  user  = "ubuntu"
  #  agent = false
  #  # путь до приватного ключа
  #  private_key = file(var.private_key_path)
  #}

  #provisioner "file" {
  #  source      = var.path_mongod_conf
  #  destination = "/tmp/mongod.conf"
  #}

  #provisioner "remote-exec" {
  #  inline = [
  #    "sudo systemctl stop mongod",
  #    "sudo mv /tmp/mongod.conf /etc/mongod.conf",
  #    "sudo systemctl start mongod"
  #  ]
  #}
}
