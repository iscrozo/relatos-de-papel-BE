package com.relatosdepapel.catalogue;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;


@SpringBootApplication
@EnableDiscoveryClient
public class BooksCatalogueApplication {

    public static void main(String[] args) {
        SpringApplication.run(BooksCatalogueApplication.class, args);
    }
}
