package com.example;

import org.slf4j.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@SpringBootApplication
@EnableScheduling
public class FluentdAppenderApplication {

    private static final Logger logger = LoggerFactory.getLogger(FluentdAppenderApplication.class);
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public static void main(String[] args) {
        SpringApplication.run(FluentdAppenderApplication.class, args);
    }

    @Scheduled(fixedRate = 1000)
    public void logCurrentTime() {
        // MDC 中的字段会自动推送给 Fluentd
        try (MDC.MDCCloseable ignored = MDC.putCloseable("requestId", UUID.randomUUID().toString())) {
            String currentTime = LocalDateTime.now().format(formatter);
            logger.info("Current time is: {}", currentTime);
        }
    }
} 