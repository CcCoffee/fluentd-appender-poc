terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create a dedicated service account for Fluentd
resource "google_service_account" "fluentd" {
  count        = var.create_service_account ? 1 : 0
  account_id   = var.service_account_id
  display_name = "Fluentd Logging Agent"
  description  = "Service account for Fluentd agent to write logs to Cloud Logging"
}

# Grant necessary permissions
resource "google_project_iam_member" "logging_writer" {
  count   = var.create_service_account ? 1 : 0
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.fluentd[0].email}"
}

# Create VPC network if specified
resource "google_compute_network" "fluentd_network" {
  count                   = var.create_network ? 1 : 0
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Create subnet if specified
resource "google_compute_subnetwork" "fluentd_subnet" {
  count         = var.create_network ? 1 : 0
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.fluentd_network[0].id
  region        = var.region
}

# Firewall rule for Fluentd forward protocol
resource "google_compute_firewall" "fluentd_forward" {
  name    = "allow-fluentd-forward"
  network = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name

  allow {
    protocol = "tcp"
    ports    = ["24224"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["fluentd-agent"]
}

# Fluentd VM instance
resource "google_compute_instance" "fluentd_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name
    subnetwork = var.create_network ? google_compute_subnetwork.fluentd_subnet[0].name : var.subnet_name

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        // Ephemeral public IP
      }
    }
  }

  metadata = {
    startup-script = file("${path.module}/scripts/startup-script.sh")
  }

  service_account {
    email  = var.create_service_account ? google_service_account.fluentd[0].email : var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = concat(["fluentd-agent"], var.additional_tags)

  allow_stopping_for_update = true
} 