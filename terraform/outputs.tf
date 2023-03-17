output "public_ip_master" {
  value = ["${google_compute_instance.vm_instance_master.*.network_interface.0.access_config.0.nat_ip}"]
}
output "public_ip_worker" {
  value = ["${google_compute_instance.vm_instance_worker.*.network_interface.0.access_config.0.nat_ip}"]
}