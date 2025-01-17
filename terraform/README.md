# GCP Logging Infrastructure with Multi-Service Support

This Terraform configuration creates a Google Cloud Platform (GCP) Managed Instance Group (MIG) with 4 instances supporting both google-fluentd logging and HTTPS services, with health checks for both services.

## Architecture Overview

- 4 GCE VM instances in a Managed Instance Group (internal network only)
- Dual service support:
  - google-fluentd for log forwarding (port 24224)
  - HTTPS service (port 8443)
- Separate health checks for each service
- Internal TCP load balancer for high availability
- Built-in google-fluentd on each instance
- Using default compute service account
- RHEL 8 base image with SELinux and firewall configuration

## Prerequisites

- Terraform >= 1.0
- Google Cloud SDK
- GCP Project with required APIs enabled:
  - Compute Engine API
  - Cloud Logging API
  - IAM API
  - Load Balancing API

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
| `logging_lb_ip` | Internal load balancer IP (use for application configuration) |
| `logging_instance_group` | Instance group URL |
| `logging_service_account` | Service account email |
| `fluentd_forward_port` | Fluentd forward protocol port (24224) |

## Infrastructure Details

### Health Checks
- Fluentd Health Check:
  - TCP check on port 24224
  - 30-second interval
  - 5-second timeout
- HTTPS Service Health Check:
  - HTTPS check on port 8443
  - Path: /health
  - 30-second interval
  - 5-second timeout

### Managed Instance Group
- 4 identical instances running both services
- Dual auto-healing policies:
  - Fluentd service (port 24224)
  - HTTPS service (port 8443)
- Base image: RHEL 8 with SELinux enabled
- Using default compute service account with cloud-platform scope

### Internal Load Balancer
- TCP load balancing for port 24224
- Automatic health checking
- Region-wide availability
- Global access enabled (accessible from all regions in VPC)

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
- Internal load balancer for high availability
- Firewall rules for both services:
  - Port 24224 (Fluentd)
  - Port 8443 (HTTPS)
- Configurable source IP ranges for internal access

## Application Configuration

### Spring Boot Application Setup

1. **Configure logback-spring.xml**:
   ```xml
   <appender name="FLUENT" class="ch.qos.logback.more.appenders.FluentLogbackAppender">
       <tag>app.${app.name}.${app.instance.id}</tag>
       <remoteHost>${FLUENTD_HOST:-LOAD_BALANCER_IP}</remoteHost>
       <port>${FLUENTD_PORT:-24224}</port>
       ...
   </appender>
   ```

2. **Get Load Balancer IP**:
   ```bash
   # Using Terraform output
   export FLUENTD_HOST=$(terraform output -raw logging_lb_ip)
   
   # Or using gcloud
   export FLUENTD_HOST=$(gcloud compute forwarding-rules describe logging-forward-rule \
       --region=REGION \
       --format="get(IPAddress)")
   ```

3. **Run Application**:
   ```bash
   java -jar your-application.jar
   ```

### High Availability Features
- Load balancer automatically routes to healthy instances
- If an instance fails, MIG creates a new one
- Applications only need to know the load balancer IP
- Automatic request distribution across all healthy instances

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

1. **High Availability**
   - Monitor both service health checks
   - Set up alerts for both services
   - Review metrics for both Fluentd and HTTPS service
   - Use appropriate timeouts for health checks

2. **Security**
   - No public IP exposure
   - Restrict `allowed_source_ranges` to your application networks
   - Use IAP or bastion host for instance access
   - Configure HTTPS certificates properly
   - Monitor both service ports

3. **Monitoring**
   - Monitor both health check results
   - Set up alerts for instance replacements
   - Track metrics for both services
   - Monitor resource usage (CPU, memory, disk)

4. **Maintenance**
   - Update both services regularly
   - Monitor disk usage for both services
   - Keep startup scripts updated for both services
   - Test both health check endpoints regularly

## References

- [Google Cloud Logging Documentation](https://cloud.google.com/logging/docs)
- [Internal TCP Load Balancing](https://cloud.google.com/load-balancing/docs/internal)
- [Managed Instance Groups Documentation](https://cloud.google.com/compute/docs/instance-groups)
- [google-fluentd Documentation](https://cloud.google.com/logging/docs/agent) 