#!/bin/bash

# Enable EPEL repository for td-agent
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Add TD repository
curl -fsSL https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh

# Install development tools for plugin installation
dnf groupinstall -y "Development Tools"
dnf install -y gcc-c++ ruby-devel

# Install GCP plugin
td-agent-gem install fluent-plugin-google-cloud

# Configure Fluentd
cat > /etc/td-agent/td-agent.conf << 'EOF'
# Input Configuration
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# GCP Cloud Logging Output Configuration
<match **>
  @type google_cloud
  
  # Use VM's built-in authentication
  use_metadata_service true
  
  # Optimize for GCP Cloud Logging
  adjust_timestamp true
  
  # Add VM metadata as labels
  enable_monitoring_label true
  
  # Configure log structure
  insert_id_key uuid
  detect_json true
  
  <buffer>
    @type memory
    flush_interval 5s
    chunk_limit_size 2M
    total_limit_size 512M
    retry_max_interval 30
    retry_forever false
    overflow_action block
  </buffer>
</match>

# Error Handling
<label @ERROR>
  <match **>
    @type stdout
    <format>
      @type json
    </format>
  </match>
</label>
EOF

# Configure SELinux for Fluentd
setsebool -P antivirus_can_scan_system 1
semanage port -a -t syslogd_port_t -p tcp 24224

# Start and enable Fluentd service
systemctl start td-agent
systemctl enable td-agent

# Open port in firewall
firewall-cmd --permanent --add-port=24224/tcp
firewall-cmd --reload

# Set up log rotation
cat > /etc/logrotate.d/td-agent << 'EOF'
/var/log/td-agent/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 td-agent td-agent
    sharedscripts
    postrotate
        pid=/var/run/td-agent/td-agent.pid
        if [ -s "$pid" ]
        then
            kill -USR1 "$(cat $pid)"
        fi
    endscript
}
EOF 