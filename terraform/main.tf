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

# Use default compute service account instead of creating a new one
# Create a custom service account for logging instances
# resource "google_service_account" "logging_service_account" {
#   account_id   = "logging-agent-sa"
#   display_name = "Logging Agent Service Account"
#   description  = "Service account for GCE instances running google-fluentd logging agent"
# }

# Grant necessary permissions to the service account
# resource "google_project_iam_member" "logging_writer" {
#   project = var.project_id
#   role    = "roles/logging.logWriter"
#   member  = "serviceAccount:${google_service_account.logging_service_account.email}"
# }

# Create instance template
resource "google_compute_instance_template" "logging_template" {
  name_prefix  = "logging-agent-template-"
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
    # Use default compute service account
    # email  = google_service_account.logging_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["logging-agent"]

  lifecycle {
    create_before_destroy = true
  }
}

# Create health check for fluentd service (for auto healing)
resource "google_compute_health_check" "fluentd_health_check" {
  count              = var.enable_tcp ? 1 : 0
  name               = "fluentd-health-check"
  check_interval_sec = 30
  timeout_sec        = 5
  
  tcp_health_check {
    port = var.tcp_port
  }
}

# Create health check for HTTPS service (for auto healing)
resource "google_compute_health_check" "https_health_check" {
  count              = var.enable_https ? 1 : 0
  name               = "https-service-health-check"
  check_interval_sec = 30
  timeout_sec        = 5

  https_health_check {
    port         = var.https_port
    request_path = var.https_health_check_path
  }
}

# Create health check for load balancer (TCP)
resource "google_compute_health_check" "lb_tcp_health_check" {
  count              = var.enable_tcp ? 1 : 0
  name               = "lb-tcp-health-check"
  check_interval_sec = 5  # 更频繁的检查间隔
  timeout_sec        = 5
  healthy_threshold  = 2  # 连续成功次数
  unhealthy_threshold = 3 # 连续失败次数
  
  tcp_health_check {
    port = var.tcp_port
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create health check for load balancer (HTTPS)
resource "google_compute_health_check" "lb_https_health_check" {
  count              = var.enable_https ? 1 : 0
  name               = "lb-https-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3
  
  https_health_check {
    port         = var.https_port
    request_path = var.https_health_check_path
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create firewall rule for Fluentd forward protocol
resource "google_compute_firewall" "logging_forward" {
  name    = "allow-logging-forward"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = concat(
      var.enable_tcp ? [tostring(var.tcp_port)] : [],
      var.enable_https ? [tostring(var.https_port)] : []
    )
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["logging-agent"]
}

# Create internal load balancer for logging agents
resource "google_compute_region_backend_service" "logging_backend" {
  name                  = "logging-backend"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  
  # 根据启用的服务选择对应的健康检查
  health_checks = (
    var.enable_tcp ? [google_compute_health_check.lb_tcp_health_check[0].id] : (
      var.enable_https ? [google_compute_health_check.lb_https_health_check[0].id] : []
    )
  )

  # 配置端口名称
  port_name = (
    var.enable_tcp ? "fluentd-forward" : (
      var.enable_https ? "https-service" : null
    )
  )

  backend {
    group = google_compute_region_instance_group_manager.logging_group.instance_group
  }
}

resource "google_compute_forwarding_rule" "logging_forwarding" {
  count                 = var.enable_tcp ? 1 : 0
  name                  = "logging-forward-rule"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.logging_backend.id
  ports                 = [tostring(var.tcp_port)]
  network               = "default"
  subnetwork           = "default"
  allow_global_access   = true
}

# 添加 HTTPS 服务的转发规则
resource "google_compute_forwarding_rule" "https_forwarding" {
  count                 = var.enable_https ? 1 : 0
  name                  = "https-forward-rule"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.logging_backend.id
  ports                 = [tostring(var.https_port)]
  network               = "default"
  subnetwork           = "default"
  allow_global_access   = true
}

# Create MIG
resource "google_compute_region_instance_group_manager" "logging_group" {
  name = "logging-agent-group"

  base_instance_name = "logging-agent"
  region            = var.region

  version {
    instance_template = google_compute_instance_template.logging_template.id
  }

  dynamic "named_port" {
    for_each = var.enable_tcp ? [1] : []
    content {
      name = "fluentd-forward"
      port = var.tcp_port
    }
  }

  dynamic "named_port" {
    for_each = var.enable_https ? [1] : []
    content {
      name = "https-service"
      port = var.https_port
    }
  }

  target_size = 4

  auto_healing_policies {
    health_check = (
      var.enable_tcp ? google_compute_health_check.fluentd_health_check[0].id : (
        var.enable_https ? google_compute_health_check.https_health_check[0].id : null
      )
    )
    initial_delay_sec = 300
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
    replacement_method    = "SUBSTITUTE"
  }
}