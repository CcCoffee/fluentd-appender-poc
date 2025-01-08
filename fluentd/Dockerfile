FROM fluent/fluentd:v1.16-1

# 使用 root 用户
USER root

# 创建日志目录并设置权限
RUN mkdir -p /fluentd/log && \
    chown -R fluent:fluent /fluentd/log

# 复制配置文件
COPY conf/fluent.conf /fluentd/etc/

# 切换回 fluent 用户
USER fluent

# 暴露端口
EXPOSE 24224 