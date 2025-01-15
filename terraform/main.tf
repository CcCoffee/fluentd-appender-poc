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

# Firewall rule for health checks
resource "google_compute_firewall" "fluentd_health_check" {
  name    = "allow-health-check"
  network = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name

  allow {
    protocol = "tcp"
    ports    = ["24224"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["fluentd-agent"]
}

# Create instance template for Fluentd VMs
resource "google_compute_instance_template" "fluentd" {
  name_prefix  = "fluentd-agent-template-"
  machine_type = var.machine_type
  
  # Instance template will be recreated when startup script changes
  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = var.instance_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.boot_disk_size
    disk_type    = var.boot_disk_type
  }

  network_interface {
    network    = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name
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
}

# Create health check for the MIG
resource "google_compute_health_check" "fluentd" {
  name                = "fluentd-health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  tcp_health_check {
    port = 24224
  }
}

# Create the Managed Instance Group
resource "google_compute_region_instance_group_manager" "fluentd" {
  name = "fluentd-agent-mig"

  base_instance_name = var.instance_name
  region            = var.region

  version {
    instance_template = google_compute_instance_template.fluentd.id
  }

  # Configure auto-healing
  auto_healing_policies {
    health_check      = google_compute_health_check.fluentd.id
    initial_delay_sec = var.auto_healing_initial_delay
  }

  # Configure target size
  target_size = var.instance_count

  named_port {
    name = "fluentd-forward"
    port = 24224
  }
}

# Optional: Configure auto-scaling
resource "google_compute_region_autoscaler" "fluentd" {
  count  = var.enable_autoscaling ? 1 : 0
  name   = "fluentd-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.fluentd.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}

# Create internal load balancer
resource "google_compute_forwarding_rule" "fluentd" {
  name                  = "fluentd-lb"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.fluentd.id
  ports                 = ["24224"]
  network              = var.create_network ? google_compute_network.fluentd_network[0].name : var.network_name
  subnetwork           = var.create_network ? google_compute_subnetwork.fluentd_subnet[0].name : var.subnet_name
}

resource "google_compute_region_backend_service" "fluentd" {
  name                  = "fluentd-backend"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.fluentd.id]

  backend {
    group = google_compute_region_instance_group_manager.fluentd.instance_group
  }
} 