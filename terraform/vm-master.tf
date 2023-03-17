resource "google_compute_instance" "vm_instance_master" {
  count        = var.count-master
  name         = "kubernetes-master-0${count.index}"
  machine_type = var.machine-type
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.ubuntu_2004_sku
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    "google-compute-default-read-write" = "true"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-full"]
  }

  network_interface {
    network = google_compute_network.network.name
    subnetwork = google_compute_subnetwork.sub_network.name
    access_config {
      // Ephemeral public IP
    }
  }
  tags = [var.firewall-target-tag]
}

