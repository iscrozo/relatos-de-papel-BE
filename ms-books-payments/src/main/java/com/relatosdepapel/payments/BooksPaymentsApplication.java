package com.relatosdepapel.payments;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class BooksPaymentsApplication {

    public static void main(String[] args) {
        SpringApplication.run(BooksPaymentsApplication.class, args);
    }
}
