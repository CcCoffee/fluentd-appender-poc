variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "create_service_account" {
  description = "Whether to create a dedicated service account"
  type        = bool
  default     = true
}

variable "service_account_id" {
  description = "The ID of the service account to create"
  type        = string
  default     = "fluentd-agent"
}

variable "service_account_email" {
  description = "The email of an existing service account to use"
  type        = string
  default     = ""
}

variable "create_network" {
  description = "Whether to create a new VPC network"
  type        = bool
  default     = false
}

variable "network_name" {
  description = "The name of the network to use or create"
  type        = string
  default     = "default"
}

variable "subnet_name" {
  description = "The name of the subnet to use or create"
  type        = string
  default     = "default"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "allowed_source_ranges" {
  description = "List of CIDR ranges that can access the Fluentd forward port"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Warning: Restrict this in production
}

variable "instance_name" {
  description = "The name of the Fluentd VM instance"
  type        = string
  default     = "fluentd-agent-vm"
}

variable "machine_type" {
  description = "The machine type for the Fluentd VM"
  type        = string
  default     = "e2-medium"
}

variable "instance_image" {
  description = "The OS image for the Fluentd VM"
  type        = string
  default     = "rhel-cloud/rhel-9"
}

variable "boot_disk_size" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-standard"
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Additional network tags for the instance"
  type        = list(string)
  default     = []
} 