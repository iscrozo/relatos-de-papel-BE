# Quick Start Guide - Relatos de Papel

Get the system up and running in minutes!

## Prerequisites

Ensure you have installed:
- **JDK 17+** (verify: `java -version`)
- **Maven 3.8+** (verify: `mvn -version`)
- **Git** (optional, for version control)

---

## Step 1: Build All Modules

From the root directory:

```bash
cd /Users/srozo/Desktop/docu
mvn clean install
```

This command:
- Compiles all 4 modules
- Downloads dependencies
- Runs tests
- Packages JARs

Expected output:
```
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] Relatos de Papel - Microservices System ........ SUCCESS
[INFO] Eureka Server - Service Discovery .............. SUCCESS
[INFO] Cloud Gateway - API Gateway .................... SUCCESS
[INFO] MS Books Catalogue ............................. SUCCESS
[INFO] MS Books Payments .............................. SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

---

## Step 2: Start Services

**IMPORTANT**: Start services in this order!

### Terminal 1: Start Eureka Server (FIRST)

```bash
cd eureka-server
mvn spring-boot:run
```

Wait for this message:
```
Started EurekaServerApplication in X.XXX seconds
```

Verify: Open http://localhost:8761 in your browser
You should see the Eureka Dashboard (no services registered yet).

---

### Terminal 2: Start Books Catalogue

```bash
cd ms-books-catalogue
mvn spring-boot:run
```

Wait for:
```
Started BooksCatalogueApplication in X.XXX seconds
```

Verify in Eureka: Refresh http://localhost:8761
You should see `MS-BOOKS-CATALOGUE` listed under "Instances currently registered"

---

### Terminal 3: Start Payments Service

```bash
cd ms-books-payments
mvn spring-boot:run
```

Wait for:
```
Started BooksPaymentsApplication in X.XXX seconds
```

Verify in Eureka: Refresh http://localhost:8761
You should see both `MS-BOOKS-CATALOGUE` and `MS-BOOKS-PAYMENTS`

---

### Terminal 4: Start Cloud Gateway (LAST)

```bash
cd cloud-gateway
mvn spring-boot:run
```

Wait for:
```
Started CloudGatewayApplication in X.XXX seconds
```

Verify in Eureka: Refresh http://localhost:8761
All three services should be registered: `MS-BOOKS-CATALOGUE`, `MS-BOOKS-PAYMENTS`, `CLOUD-GATEWAY`

---

## Step 3: Verify System is Running

### Quick Health Check

```bash
# Gateway
curl http://localhost:8080/actuator/health

# Books Catalogue
curl http://localhost:8081/actuator/health

# Payments
curl http://localhost:8082/actuator/health
```

All should return: `{"status":"UP"}`

### Check Eureka Dashboard

Open: http://localhost:8761

You should see all services with status "UP".

---

## Step 4: Test the System

### Test 1: Get All Books

```bash
curl http://localhost:8080/api/books
```

Expected: JSON array with 10 sample books (loaded from `data.sql`)

### Test 2: Get a Specific Book

```bash
curl http://localhost:8080/api/books/2
```

Expected: Details of "Cien Años de Soledad" by Gabriel García Márquez

### Test 3: Process a Payment (Complete Flow!)

```bash
curl -X POST http://localhost:8080/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "bookId": 2,
    "quantity": 1,
    "customerName": "Test User",
    "customerEmail": "test@example.com",
    "paymentMethod": "CREDIT_CARD"
  }'
```

Expected: Payment confirmation with status "COMPLETED"

This command:
1. Validates book exists (calls Books Catalogue)
2. Checks stock availability
3. Processes payment
4. Reduces stock automatically
5. Returns payment details

### Test 4: Verify Stock Was Reduced

```bash
curl http://localhost:8080/api/books/2
```

Check the `stock` field - it should be reduced by 1!

---

## Step 5: Access Web Interfaces

### Eureka Dashboard
```
http://localhost:8761
```
- View registered services
- Check instance status
- Monitor service health

### H2 Database Console - Books Catalogue
```
http://localhost:8081/h2-console
```
- JDBC URL: `jdbc:h2:mem:cataloguedb`
- Username: `sa`
- Password: (leave empty)

Run query:
```sql
SELECT * FROM books;
```

### H2 Database Console - Payments
```
http://localhost:8082/h2-console
```
- JDBC URL: `jdbc:h2:mem:paymentsdb`
- Username: `sa`
- Password: (leave empty)

Run query:
```sql
SELECT * FROM payments;
```

---

## Common Commands

### Stop a Service
- Press `Ctrl + C` in the terminal running the service

### Restart a Service
```bash
# Stop with Ctrl+C, then:
mvn spring-boot:run
```

### Clean Build
```bash
mvn clean install
```

### Run Without Tests
```bash
mvn spring-boot:run -DskipTests
```

### Package as JAR
```bash
mvn clean package
java -jar target/eureka-server-1.0.0-SNAPSHOT.jar
```

---

## Troubleshooting

### Issue: "Port already in use"

**Solution**: Kill the process using that port

```bash
# macOS/Linux
lsof -ti:8761 | xargs kill -9  # Replace 8761 with your port

# Windows
netstat -ano | findstr :8761
taskkill /PID <PID> /F
```

### Issue: "Service not registered in Eureka"

**Solution**:
1. Verify Eureka Server is running on 8761
2. Wait 30 seconds for registration
3. Check application.yml has correct Eureka URL

### Issue: "Cannot connect to database"

**Solution**: 
- H2 is in-memory; restart the service
- Check H2 console URL matches `application.yml`

### Issue: "Circuit breaker open"

**Solution**:
- Ensure Books Catalogue is running
- Wait 5 seconds for circuit to half-open
- Try request again

### Issue: "Books Catalogue service unavailable"

**Solution**:
1. Check Books Catalogue is running: `curl http://localhost:8081/actuator/health`
2. Check it's registered in Eureka: http://localhost:8761
3. Restart Books Catalogue if needed

---

## Development Workflow

### Making Changes

1. **Stop the affected service** (Ctrl+C)
2. **Make code changes**
3. **Rebuild**:
   ```bash
   mvn clean install -DskipTests
   ```
4. **Restart the service**:
   ```bash
   mvn spring-boot:run
   ```

### Adding New Books

Via API:
```bash
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Nueva Novela",
    "author": "Autor Nuevo",
    "isbn": "978-84-376-9999-9",
    "price": 19.99,
    "stock": 50,
    "category": "Ficción"
  }'
```

Via H2 Console:
```sql
INSERT INTO books (title, author, isbn, price, stock, category, created_at, updated_at) 
VALUES ('Nueva Novela', 'Autor Nuevo', '978-84-376-9999-9', 19.99, 50, 'Ficción', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

---

## Next Steps

1. **Read the API Testing Guide**: `API_TESTING_GUIDE.md`
   - Comprehensive API examples
   - Test scenarios
   - Error handling

2. **Review the Architecture**: `ARCHITECTURE.md`
   - System design
   - Communication patterns
   - Resilience mechanisms

3. **Explore the Code**:
   - Start with controller classes
   - Review service layer logic
   - Understand repository patterns

4. **Extend the System**:
   - Add new microservices
   - Implement additional features
   - Enhance resilience patterns

---

## Service Ports Reference

| Service | Port | URL |
|---------|------|-----|
| Eureka Server | 8761 | http://localhost:8761 |
| Cloud Gateway | 8080 | http://localhost:8080 |
| Books Catalogue | 8081 | http://localhost:8081 |
| Payments | 8082 | http://localhost:8082 |

---

## Useful URLs

| Description | URL |
|-------------|-----|
| Eureka Dashboard | http://localhost:8761 |
| Gateway Health | http://localhost:8080/actuator/health |
| Books API | http://localhost:8080/api/books |
| Payments API | http://localhost:8080/api/payments |
| Books H2 Console | http://localhost:8081/h2-console |
| Payments H2 Console | http://localhost:8082/h2-console |
| Circuit Breaker Status | http://localhost:8082/actuator/circuitbreakers |

---

## Getting Help

- Check logs in the terminal where services are running
- Review Eureka dashboard for service status
- Test direct microservice access (bypass gateway)
- Verify database content via H2 console

---

Happy coding! 🚀
