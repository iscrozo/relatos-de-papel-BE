# Build stage (context = repo root: docker build -f ms-books-catalogue/Dockerfile .)
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

COPY pom.xml .
COPY eureka-server/pom.xml eureka-server/
COPY cloud-gateway/pom.xml cloud-gateway/
COPY ms-books-catalogue/pom.xml ms-books-catalogue/
COPY ms-books-payments/pom.xml ms-books-payments/
COPY ms-users/pom.xml ms-users/
RUN mvn -pl ms-books-catalogue dependency:go-offline -B -q

COPY ms-books-catalogue ms-books-catalogue/
RUN mvn -pl ms-books-catalogue package -DskipTests -B -q

# Run stage
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY --from=builder /build/ms-books-catalogue/target/ms-books-catalogue-*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
