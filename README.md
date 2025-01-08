# Fluentd Appender POC

这是一个基于 Spring Boot 3.3.7 的示例项目，演示如何使用 [logback-more-appenders](https://github.com/sndyuk/logback-more-appenders) 将应用日志通过 Fluentd 进行收集和处理。

## 项目功能

该项目实现以下功能：
1. 每秒通过 logback appender 输出当前时间到日志
2. logback appender 将应用日志通过 LOGGER 输出到 fluentd agent
3. fluentd agent 最终将日志输出写入到本地文件中

## 技术栈

- Spring Boot 3.3.7
- logback-more-appenders
- Fluentd
- Docker

## 依赖配置

项目使用 Maven 进行依赖管理。主要依赖包括：
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <version>3.3.7</version>
</dependency>
<dependency>
    <groupId>com.sndyuk</groupId>
    <artifactId>logback-more-appenders</artifactId>
    <version>1.8.8</version>
</dependency>
```

## 运行说明

### 使用 Docker 运行 Fluentd

1. 构建并启动 Fluentd 容器：
```bash
docker-compose up -d
```

2. 检查容器状态：
```bash
docker-compose ps
```

3. 查看日志输出：
```bash
# 日志文件位于 ./logs 目录下
```

4. 运行 Spring Boot 应用

### 目录结构
```
.
├── docker-compose.yml          # Docker 编排文件
├── fluentd/                    # Fluentd 相关文件
│   ├── Dockerfile             # Fluentd 镜像构建文件
│   └── conf/                  # Fluentd 配置文件目录
│       └── fluent.conf       # Fluentd 主配置文件
├── logs/                      # 日志输出目录（由 Docker 挂载）
```

## 配置文件

### Logback 配置
项目使用以下配置文件作为参考：
[logback-appenders-fluentd.xml](https://github.com/sndyuk/logback-more-appenders/blob/master/src/test/resources/logback-appenders-fluentd.xml)

### Fluentd 配置
Fluentd 配置文件位于 `fluentd/conf/fluent.conf`，主要配置包括：
- 监听 24224 端口接收日志
- 将日志输出到 `/fluentd/log` 目录（对应主机的 `./logs` 目录）
- 使用 JSON 格式存储日志

## 注意事项

1. 确保 Docker 环境正常运行
2. 确保 24224 端口未被占用
3. 检查 `logs` 目录的写入权限
4. 可以通过修改 `fluent.conf` 自定义日志格式和输出位置



