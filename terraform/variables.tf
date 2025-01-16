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