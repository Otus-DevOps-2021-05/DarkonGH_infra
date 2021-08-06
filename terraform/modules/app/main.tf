resource "yandex_compute_instance" "app" {
  name = var.name
  allow_stopping_for_update = true
  labels = {
    tags = "reddit-app"
  }
  resources {
    cores  = var.cores
    memory = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "echo DATABASE_URL=${var.db_ip} > dburl.txt"
    ]
  }
  provisioner "file" {
    source      = var.path_puma_service
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = var.path_deploy_script
  }
}
