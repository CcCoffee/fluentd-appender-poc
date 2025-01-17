variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "machine_type" {
  description = "The machine type for instances"
  type        = string
  default     = "e2-medium"
}

variable "allowed_source_ranges" {
  description = "List of CIDR ranges allowed to connect to Fluentd forward port"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 建议在生产环境中限制
}

variable "enable_https" {
  description = "Whether to enable HTTPS service"
  type        = bool
  default     = false
}

variable "https_port" {
  description = "Port for HTTPS service"
  type        = number
  default     = 8443
}

variable "https_health_check_path" {
  description = "Health check path for HTTPS service"
  type        = string
  default     = "/health"
}

variable "enable_tcp" {
  description = "Whether to enable TCP forward service"
  type        = bool
  default     = true
}

variable "tcp_port" {
  description = "Port for TCP forward service"
  type        = number
  default     = 24224
} 