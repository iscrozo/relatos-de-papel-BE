# Build stage (context = repo root: docker build -f cloud-gateway/Dockerfile .)
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

COPY pom.xml .
COPY eureka-server/pom.xml eureka-server/
COPY cloud-gateway/pom.xml cloud-gateway/
COPY ms-books-catalogue/pom.xml ms-books-catalogue/
COPY ms-books-payments/pom.xml ms-books-payments/
RUN mvn -pl cloud-gateway dependency:go-offline -B -q

COPY cloud-gateway cloud-gateway/
RUN mvn -pl cloud-gateway package -DskipTests -B -q

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/cloud-gateway/target/cloud-gateway-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
