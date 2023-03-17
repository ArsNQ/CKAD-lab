resource "google_compute_network" "network" {
  name          = var.network-name
}

resource "google_compute_subnetwork" "sub_network" {
  name          = var.subnetwork-name
  region        = var.region
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.network.name
}

resource "google_compute_firewall" "firewall" {
  name          = var.firewall-name
  network       = google_compute_network.network.name
  direction     = "INGRESS"
  priority      = 1000

  allow {
    protocol    = "tcp"
    ports       = ["22", "80", "443", "6443", "8472", "8090", "8091", "10248", "10250", "10255"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.firewall-target-tag]
}