#vm
resource "yandex_compute_instance" "vm" {
  count       = 2
  name        = "ssshost${count.index + 1}"
  hostname    = "ssshost${count.index + 1}"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 8
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ssssub-b.id
    nat       = true
  }

  metadata = {
    user-data = "${file("./metadata.yaml")}"
  }
}

#network
resource "yandex_vpc_network" "sssnet" {
  name = "sssnet"
}

#subnet
resource "yandex_vpc_subnet" "ssssub-b" {
  name = "ssssub-b"
  v4_cidr_blocks = ["192.168.0.0/24"]
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.sssnet.id}"
}

#target group
resource "yandex_lb_target_group" "sss-tg" {
  name      = "sss-tg"

  target {
    subnet_id = "${yandex_vpc_subnet.ssssub-b.id}"
    address   = "${yandex_compute_instance.vm[0].network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.ssssub-b.id}"
    address   = "${yandex_compute_instance.vm[1].network_interface.0.ip_address}"
  }
}

#network load balancer
resource "yandex_lb_network_load_balancer" "sss-net-lb" {
  name = "sss-net-lb"

  listener {
    name = "web-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.sss-tg.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
