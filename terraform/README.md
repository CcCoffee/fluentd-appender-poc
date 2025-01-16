# GCP Logging Infrastructure with google-fluentd

This Terraform configuration creates a Google Cloud Platform (GCP) Managed Instance Group (MIG) with 4 instances, each running google-fluentd to collect and forward application logs to Cloud Logging.

## Architecture Overview

- 4 GCE VM instances in a Managed Instance Group (internal network only)
- Built-in google-fluentd on each instance
- TCP port 24224 for log forwarding (internal access only)
- Automatic health checks and instance recovery
- Custom service account with minimal permissions
- RHEL 8 base image with SELinux and firewall configuration

## Prerequisites

- Terraform >= 1.0
- Google Cloud SDK
- GCP Project with required APIs enabled:
  - Compute Engine API
  - Cloud Logging API
  - IAM API

## Configuration Files

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Variable definitions
- `outputs.tf`: Output definitions
- `terraform.tfvars`: Variable values (create from example)
- `scripts/`:
  - `startup-script.sh`: VM initialization script
  - `app-forward.conf`: google-fluentd configuration

## Quick Start

1. **Prepare Configuration**

   ```bash
   # Copy and edit the variables file
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit with your values
   vim terraform.tfvars
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Review the Plan**

   ```bash
   terraform plan
   ```

4. **Apply Configuration**

   ```bash
   terraform apply
   ```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | GCP Project ID | string | - |
| `region` | GCP Region | string | - |
| `machine_type` | VM Machine Type | string | "e2-medium" |
| `allowed_source_ranges` | Allowed CIDR ranges | list(string) | ["0.0.0.0/0"] |

## Outputs

| Name | Description |
|------|-------------|
| `instance_group` | Instance group URL |
| `service_account` | Service account email |
| `instances_self_links` | List of instance self-links |

## Infrastructure Details

### Managed Instance Group
- 4 identical instances
- Automatic health checks (TCP port 24224)
- Auto-healing enabled
- Base image: RHEL 8 with SELinux enabled

### google-fluentd Configuration
- Forward protocol input on port 24224
- JSON log parsing
- Original timestamp preservation
- Buffering with file backend
- Custom labels for app name and instance ID
- SELinux and firewall rules properly configured

### Networking
- Default VPC network
- Internal network only (no public IP)
- Firewall rules for port 24224
- Configurable source IP ranges for internal access

### Security
- No public IP exposure
- Custom service account with minimal permissions
- Only required Cloud API access
- Network access control via firewall rules

## Maintenance

### Check Instance Status
```bash
# List all instances in the group
gcloud compute instance-groups managed list-instances app-instance-group \
    --region=REGION

# SSH to instances requires Identity-Aware Proxy (IAP) or bastion host
gcloud compute ssh app-instance-name --tunnel-through-iap
```

### Check google-fluentd Status
```bash
# Check service status
sudo systemctl status google-fluentd

# View logs
sudo tail -f /var/log/google-fluentd/google-fluentd.log
```

### Update Configuration
1. Modify `scripts/app-forward.conf`
2. Apply changes:
   ```bash
   terraform apply
   ```
   Note: This will create new instances with updated configuration

## Troubleshooting

### Common Issues

1. **Instances not starting**
   - Check startup script logs:
     ```bash
     sudo journalctl -u google-startup-scripts
     ```

2. **Logs not appearing in Cloud Logging**
   - Verify google-fluentd service:
     ```bash
     sudo systemctl status google-fluentd
     ```
   - Check permissions:
     ```bash
     gcloud projects get-iam-policy PROJECT_ID
     ```

3. **Connection Issues**
   - Verify firewall rules:
     ```bash
     gcloud compute firewall-rules list
     ```
   - Check network connectivity:
     ```bash
     telnet INSTANCE_IP 24224
     ```

## Clean Up

To remove all created resources:

```bash
terraform destroy
```

## Best Practices

1. **Security**
   - No public IP exposure ensures better security
   - Restrict `allowed_source_ranges` to your application networks
   - Use IAP or bastion host for instance access
   - Regularly review service account permissions
   - Monitor firewall rule changes

2. **Monitoring**
   - Set up alerts for instance health
   - Monitor google-fluentd metrics
   - Review Cloud Logging quotas

3. **Maintenance**
   - Regularly update google-fluentd
   - Monitor disk usage for log buffers
   - Keep startup scripts up to date

## References

- [Google Cloud Logging Documentation](https://cloud.google.com/logging/docs)
- [Managed Instance Groups Documentation](https://cloud.google.com/compute/docs/instance-groups)
- [google-fluentd Documentation](https://cloud.google.com/logging/docs/agent) 