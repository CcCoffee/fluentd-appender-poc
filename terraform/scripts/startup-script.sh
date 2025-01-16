#!/bin/bash

# 安装 EPEL 仓库
sudo dnf install -y epel-release

# 确保google-fluentd已安装并运行
if ! systemctl is-active --quiet google-fluentd; then
    # 如果服务不存在或未运行，安装google-fluentd
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install

    # 安装依赖
    sudo dnf install -y gcc-c++ ruby-devel
fi

# 创建配置目录（如果不存在）
sudo mkdir -p /etc/google-fluentd/config.d/

# 写入应用日志转发配置
cat << 'EOF' | sudo tee /etc/google-fluentd/config.d/app-forward.conf
${fluentd_config}
EOF

# 设置正确的权限
sudo chown -R google-fluentd:google-fluentd /etc/google-fluentd
sudo chmod -R 644 /etc/google-fluentd/config.d/

# 创建缓冲目录
sudo mkdir -p /var/lib/google-fluentd/app-buffers
sudo chown -R google-fluentd:google-fluentd /var/lib/google-fluentd

# 配置SELinux（RHEL特有）
sudo setsebool -P antivirus_can_scan_system 1
sudo semanage port -a -t syslogd_port_t -p tcp 24224 || true

# 配置防火墙
sudo firewall-cmd --permanent --add-port=24224/tcp
sudo firewall-cmd --reload

# 重启google-fluentd服务
sudo systemctl restart google-fluentd

# 等待服务启动
sleep 30

# 验证服务状态
if ! systemctl is-active --quiet google-fluentd; then
    echo "ERROR: google-fluentd failed to start"
    exit 1
fi 