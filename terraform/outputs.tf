output "instance_name" {
  description = "The name of the created Fluentd instance"
  value       = google_compute_instance.fluentd_vm.name
}

output "instance_ip_internal" {
  description = "The internal IP address of the Fluentd instance"
  value       = google_compute_instance.fluentd_vm.network_interface[0].network_ip
}

output "instance_ip_external" {
  description = "The external IP address of the Fluentd instance"
  value       = var.assign_public_ip ? google_compute_instance.fluentd_vm.network_interface[0].access_config[0].nat_ip : null
}

output "service_account_email" {
  description = "The email of the service account used by Fluentd instances"
  value       = var.create_service_account ? google_service_account.fluentd[0].email : var.service_account_email
}

output "fluentd_forward_port" {
  description = "The port number for Fluentd forward protocol"
  value       = "24224"
}

output "network_name" {
  description = "The name of the network being used"
  value       = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name
}

output "subnet_name" {
  description = "The name of the subnet being used"
  value       = var.create_network ? google_compute_subnetwork.fluentd_subnet[0].name : var.subnet_name
}

output "instance_group_manager" {
  description = "The name of the instance group manager"
  value       = google_compute_region_instance_group_manager.fluentd.name
}

output "instance_group" {
  description = "The instance group URL"
  value       = google_compute_region_instance_group_manager.fluentd.instance_group
}

output "instance_template" {
  description = "The name of the instance template"
  value       = google_compute_instance_template.fluentd.name
}

output "load_balancer_ip" {
  description = "The internal IP address of the load balancer"
  value       = google_compute_forwarding_rule.fluentd.ip_address
}

output "health_check" {
  description = "The name of the health check"
  value       = google_compute_health_check.fluentd.name
}

output "autoscaler" {
  description = "The name of the autoscaler (if enabled)"
  value       = var.enable_autoscaling ? google_compute_region_autoscaler.fluentd[0].name : null
} 