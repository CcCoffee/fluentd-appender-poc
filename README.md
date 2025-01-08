# Fluentd Appender POC

这是一个使用 Spring Boot 3.2.1 的示例项目，演示如何使用 logback-more-appenders 将应用程序日志转发到 Fluentd。

## 功能特性

- 每秒输出当前时间的日志
- 使用 Fluentd 收集应用程序日志
- 支持将日志输出到文件系统
- 支持将日志转发到 Google Cloud Logging（可选）

## 技术栈

- Spring Boot 3.2.1
- Logback More Appenders 1.8.8
- Fluentd v1.16
- Google Cloud Logging（可选）

## Maven 依赖配置

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter</artifactId>
    </dependency>
    <dependency>
        <groupId>com.sndyuk</groupId>
        <artifactId>logback-more-appenders</artifactId>
        <version>1.8.8</version>
    </dependency>
    <dependency>
        <groupId>org.fluentd</groupId>
        <artifactId>fluent-logger</artifactId>
        <version>0.3.4</version>
    </dependency>
</dependencies>
```

## 运行说明

1. 启动 Fluentd 容器：
```bash
docker-compose up -d
```

2. 运行 Spring Boot 应用：
```bash
./mvnw spring-boot:run
```

## 配置文件说明

### Fluentd 配置

项目提供了两种 Fluentd 配置方案：

1. 基础配置 - 输出到文件系统：
```xml
<match **>
  @type file
  path /fluentd/log/output
  append true
  <buffer>
    timekey 1d
    timekey_use_utc true
    timekey_wait 10s
  </buffer>
  <format>
    @type json
  </format>
</match>
```

2. Google Cloud Logging 配置（可选）：
```xml
<match **>
  @type google_cloud
  use_metadata_service true
  adjust_timestamp true
  
  <buffer>
    @type memory
    flush_interval 5s
    chunk_limit_size 2M
    total_limit_size 512M
    retry_max_interval 30
    retry_forever false
  </buffer>
</match>
```

### 多目标输出配置

您也可以同时将日志输出到多个目标（文件系统和 GCP Cloud Logging）：
```xml
<match **>
  @type copy
  <store>
    @type google_cloud
    # GCP Cloud Logging 配置
  </store>
  <store>
    @type file
    # 文件输出配置
  </store>
</match>
```

## GCP Cloud Logging 集成说明

要启用 GCP Cloud Logging 集成，需要：

1. 确保您有足够的 GCP 权限：
   - 如果在 GCP VM 上运行，使用默认的服务账号
   - 如果在本地运行，需要配置服务账号密钥

2. 修改 Fluentd 配置：
   - 在 GCP VM 上运行时：
     ```xml
     <match **>
       @type google_cloud
       use_metadata_service true
     </match>
     ```
   - 在本地环境运行时：
     ```xml
     <match **>
       @type google_cloud
       project_id YOUR_PROJECT_ID
       credentials_json /path/to/service/account/key.json
     </match>
     ```

3. 安装必要的 Fluentd 插件：
   ```bash
   fluent-gem install fluent-plugin-google-cloud
   ```

## 注意事项

1. 确保 Docker 和 Docker Compose 已安装
2. 检查 24224 端口是否可用
3. 如果使用 GCP Cloud Logging：
   - 确保有适当的 IAM 权限
   - 在本地运行时需要配置服务账号密钥
   - 注意 GCP 相关的费用

## 目录结构

```
.
├── README.md
├── pom.xml
├── src/
│   └── main/
│       ├── java/
│       └── resources/
│           ├── application.yml
│           └── logback-spring.xml
├── fluentd/
│   ├── Dockerfile
│   └── conf/
│       └── fluent.conf
└── docker-compose.yml
```

## 日志输出示例

1. 控制台输出：
```
2025-01-08 17:36:21 [scheduling-1] INFO  c.e.FluentdAppenderApplication - Current time is: 2025-01-08 17:36:21
```

2. Fluentd JSON 输出：
```json
{
  "level": "INFO",
  "service": "fluentd-appender-poc",
  "thread": "scheduling-1",
  "class": "com.example.FluentdAppenderApplication",
  "message": "Current time is: 2025-01-08 17:36:21"
}
```

3. GCP Cloud Logging：
   - 在 GCP Console 的 Logging Explorer 中可查看结构化日志
   - 支持按服务名、日志级别等字段进行过滤和查询



