# Build stage (context = repo root: docker build -f ms-books-payments/Dockerfile .)
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

COPY pom.xml .
COPY eureka-server/pom.xml eureka-server/
COPY cloud-gateway/pom.xml cloud-gateway/
COPY ms-books-catalogue/pom.xml ms-books-catalogue/
COPY ms-books-payments/pom.xml ms-books-payments/
RUN mvn -pl ms-books-payments dependency:go-offline -B -q

COPY ms-books-payments ms-books-payments/
RUN mvn -pl ms-books-payments package -DskipTests -B -q

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/ms-books-payments/target/ms-books-payments-*.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
