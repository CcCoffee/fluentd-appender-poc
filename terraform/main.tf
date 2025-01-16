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
}

# Create a custom service account for the instances
resource "google_service_account" "app_service_account" {
  account_id   = "app-service-account"
  display_name = "Application Service Account"
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Create instance template
resource "google_compute_instance_template" "app_template" {
  name_prefix  = "app-template-"
  machine_type = var.machine_type
  
  disk {
    source_image = "rhel-cloud/rhel-8"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script = templatefile("${path.module}/scripts/startup-script.sh", {
      fluentd_config = file("${path.module}/scripts/app-forward.conf")
    })
  }

  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["app-instance"]

  lifecycle {
    create_before_destroy = true
  }
}

# Create health check
resource "google_compute_health_check" "app_health_check" {
  name               = "app-health-check"
  check_interval_sec = 30
  timeout_sec        = 5
  
  tcp_health_check {
    port = 24224
  }
}

# Create MIG
resource "google_compute_region_instance_group_manager" "app_group" {
  name = "app-instance-group"

  base_instance_name = "app"
  region            = var.region

  version {
    instance_template = google_compute_instance_template.app_template.id
  }

  named_port {
    name = "fluentd-forward"
    port = 24224
  }

  target_size = 4  # 固定4个实例

  auto_healing_policies {
    health_check      = google_compute_health_check.app_health_check.id
    initial_delay_sec = 300
  }
}

# Create firewall rule for Fluentd forward protocol
resource "google_compute_firewall" "fluentd_forward" {
  name    = "allow-fluentd-forward"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["24224"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["app-instance"]
} 