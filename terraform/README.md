# Fluentd GCP Cloud Logging Terraform Module

This Terraform module deploys a Fluentd logging agent on Google Cloud Platform (GCP) that forwards logs to Cloud Logging. The module sets up a RHEL-based VM instance with Fluentd configured to receive logs via the forward protocol and send them to GCP Cloud Logging.

## Features

- Deploys a RHEL 9 VM instance with Fluentd agent
- Configures Fluentd for GCP Cloud Logging integration
- Supports both default and custom service accounts
- Flexible network configuration (existing or new VPC)
- Includes security best practices
- Automated setup with startup scripts

## Prerequisites

- Terraform >= 1.0
- Google Cloud Platform account
- Required GCP APIs enabled:
  - Compute Engine API
  - Cloud Logging API
  - IAM API
- Appropriate GCP permissions to create:
  - VM instances
  - Service accounts
  - IAM roles
  - VPC networks (if creating new network)

## Variable Assignment Methods

### 1. Using terraform.tfvars (Recommended)

Create a `terraform.tfvars` file in your working directory:

```hcl
# Required variables
project_id = "your-project-id"
region     = "asia-east1"
zone       = "asia-east1-a"

# Service account configuration
create_service_account = true
service_account_id    = "custom-fluentd-agent"

# Network configuration
create_network = true
network_name   = "logging-network"
subnet_name    = "logging-subnet"
subnet_cidr    = "10.0.1.0/24"

# Instance configuration
instance_name   = "prod-fluentd-agent"
machine_type    = "e2-small"
boot_disk_size  = 30
```

### 2. Using Command Line Flags

You can pass variables directly via command line:

```bash
terraform apply \
  -var="project_id=your-project-id" \
  -var="region=asia-east1" \
  -var="zone=asia-east1-a" \
  -var="create_network=true"
```

### 3. Using Environment Variables

Export variables with `TF_VAR_` prefix:

```bash
export TF_VAR_project_id="your-project-id"
export TF_VAR_region="asia-east1"
export TF_VAR_zone="asia-east1-a"
terraform apply
```

### 4. Using auto.tfvars Files

Create files with names ending in `.auto.tfvars` or `.auto.tfvars.json`:

```hcl
# production.auto.tfvars
project_id = "prod-project-id"
region     = "asia-east1"
zone       = "asia-east1-a"
```

### Variable Precedence (Highest to Lowest)

1. Command line flags (`-var` and `-var-file`)
2. `*.auto.tfvars` files (alphabetical order)
3. `terraform.tfvars`
4. Environment variables
5. Default values in variable declarations

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your configuration:
```hcl
# Required variables
project_id = "your-project-id"
region     = "us-central1"
zone       = "us-central1-a"

# Optional: Use existing network
create_network = false
network_name   = "default"
subnet_name    = "default"

# Security: Restrict source ranges
allowed_source_ranges = ["10.0.0.0/8"]
```

3. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## Examples

### Basic Usage with Default Network

```hcl
module "fluentd_agent" {
  source     = "./terraform"
  project_id = "my-project"
  region     = "us-central1"
  zone       = "us-central1-a"
}
```

### Custom Network Configuration

```hcl
module "fluentd_agent" {
  source         = "./terraform"
  project_id     = "my-project"
  region         = "us-central1"
  zone           = "us-central1-a"
  create_network = true
  network_name   = "fluentd-network"
  subnet_name    = "fluentd-subnet"
  subnet_cidr    = "10.0.1.0/24"
}
```

### Using Existing Service Account

```hcl
module "fluentd_agent" {
  source                 = "./terraform"
  project_id            = "my-project"
  region                = "us-central1"
  zone                  = "us-central1-a"
  create_service_account = false
  service_account_email = "existing-sa@my-project.iam.gserviceaccount.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | string | - | yes |
| region | The GCP region | string | - | yes |
| zone | The GCP zone | string | - | yes |
| create_service_account | Whether to create a dedicated service account | bool | true | no |
| service_account_id | The ID of the service account to create | string | "fluentd-agent" | no |
| create_network | Whether to create a new VPC network | bool | false | no |
| network_name | The name of the network to use or create | string | "default" | no |
| instance_name | The name of the Fluentd VM instance | string | "fluentd-agent-vm" | no |
| machine_type | The machine type for the Fluentd VM | string | "e2-medium" | no |
| boot_disk_size | The size of the boot disk in GB | number | 20 | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the created Fluentd instance |
| instance_ip_internal | The internal IP address of the Fluentd instance |
| instance_ip_external | The external IP address of the Fluentd instance |
| service_account_email | The email of the service account used by the instance |
| fluentd_forward_port | The port number for Fluentd forward protocol |

## Network Security

The module creates necessary firewall rules for Fluentd operation:
- TCP port 24224 for Fluentd forward protocol
- Configurable source ranges for access control

## Maintenance

The module includes:
- Automated log rotation configuration
- SELinux and firewall configuration for RHEL
- Monitoring setup options

## Notes

1. **Security**: 
   - Restrict `allowed_source_ranges` in production
   - Consider using a dedicated service account
   - Enable only necessary API access

2. **Networking**:
   - Default configuration uses existing network
   - Custom network creation available if needed
   - Consider network security best practices

3. **Logging**:
   - Configure appropriate buffer sizes based on log volume
   - Monitor disk usage and log rotation
   - Review Cloud Logging quotas and pricing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This module is licensed under the MIT License - see the LICENSE file for details. 