provider "google" {
  version     = "4.52.0"
  project     = var.project-name
  region      = var.region
  zone        = var.zone
}