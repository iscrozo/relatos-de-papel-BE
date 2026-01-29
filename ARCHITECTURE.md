# Architecture Documentation - Relatos de Papel

## System Overview

Relatos de Papel is a comprehensive microservices-based system for managing book catalogues and payment processing. The architecture follows Spring Cloud best practices with service discovery, API gateway patterns, and resilience mechanisms.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│  (Web App / Mobile App / Third-party Integrations)              │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud Gateway (Port 8080)                               │  │
│  │  - Request Routing                                       │  │
│  │  - Load Balancing                                        │  │
│  │  - Proxy Inverso Pattern (POST → GET/PUT/PATCH/DELETE)  │  │
│  │  - Cross-cutting Concerns (Logging, Monitoring)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SERVICE DISCOVERY LAYER                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Eureka Server (Port 8761)                               │  │
│  │  - Service Registration                                  │  │
│  │  - Service Discovery                                     │  │
│  │  - Health Monitoring                                     │  │
│  │  - Load Balancer Registry                                │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────┬───────────────────────────┬────────────────────┘
                │                           │
       ┌────────┴────────┐         ┌───────┴────────┐
       ▼                 ▼         ▼                ▼
┌──────────────┐  ┌──────────────────────────────────────┐
│              │  │   MICROSERVICES LAYER                 │
│              │  │                                        │
│              │  │  ┌────────────────────────────────┐   │
│              │  │  │ MS Books Catalogue (8081)      │   │
│  Database    │  │  │ - Book CRUD operations         │   │
│  Layer       │  │  │ - Stock management             │   │
│              │  │  │ - Search & filtering           │   │
│  H2 (Dev)    │  │  │ - Inventory control            │   │
│  PostgreSQL  │◄─┼──┤ - Exposes REST APIs            │   │
│  MySQL       │  │  └────────────────────────────────┘   │
│  (Prod)      │  │           │                            │
│              │  │           │ HTTP/REST (via Eureka)     │
│              │  │           ▼                            │
│              │  │  ┌────────────────────────────────┐   │
│              │  │  │ MS Books Payments (8082)       │   │
│              │  │  │ - Payment processing           │   │
│              │◄─┼──┤ - Order management             │   │
│              │  │  │ - Inter-service calls          │   │
│              │  │  │ - Circuit breaker pattern      │   │
│              │  │  │ - Resilience4j integration     │   │
│              │  │  └────────────────────────────────┘   │
└──────────────┘  └──────────────────────────────────────┘
```

---

## Component Details

### 1. Eureka Server (Service Discovery)

**Purpose**: Central registry for all microservices

**Port**: 8761

**Key Features**:
- Service registration and deregistration
- Health checking
- Service instance information
- Load balancer registry
- Dashboard UI for monitoring

**Configuration Highlights**:
```yaml
eureka:
  client:
    register-with-eureka: false  # Server doesn't register itself
    fetch-registry: false
  server:
    enable-self-preservation: false  # Disabled for dev
```

**Service Names Registered**:
- `ms-books-catalogue`
- `ms-books-payments`
- `cloud-gateway`

---

### 2. Cloud Gateway (API Gateway)

**Purpose**: Single entry point for all client requests

**Port**: 8080

**Key Features**:

#### Standard Gateway Features:
- Request routing to microservices
- Load balancing via Eureka
- Service discovery integration
- Health checks and monitoring
- Route-based forwarding

#### Proxy Inverso Pattern (Unique Feature):
Implements a special pattern that transcribes POST requests into appropriate HTTP methods.

**How it works**:
```
Client sends:
POST /api/books/action
{
  "method": "GET",
  "path": "/api/books/123"
}

Gateway transcribes to:
GET http://ms-books-catalogue/api/books/123
```

**Benefits**:
- Simplifies frontend implementation
- Single HTTP method for all operations
- Flexible request handling
- Useful for restricted environments (firewall rules)

**Routing Configuration**:
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: ms-books-catalogue
          uri: lb://ms-books-catalogue
          predicates:
            - Path=/api/books/**
        
        - id: ms-books-payments
          uri: lb://ms-books-payments
          predicates:
            - Path=/api/payments/**
```

---

### 3. MS Books Catalogue

**Purpose**: Book inventory and catalogue management

**Port**: 8081

**Service Name**: `ms-books-catalogue`

**Database**: H2 in-memory (dev) / PostgreSQL or MySQL (prod)

**Domain Model**:
```java
Book {
  - id: Long
  - title: String
  - author: String
  - isbn: String (unique)
  - price: BigDecimal
  - stock: Integer
  - description: String
  - publisher: String
  - publicationYear: Integer
  - category: String
  - createdAt: LocalDateTime
  - updatedAt: LocalDateTime
}
```

**Key Features**:

1. **CRUD Operations**:
   - Create, Read, Update, Delete books
   - Input validation
   - Duplicate ISBN prevention

2. **Search & Filtering**:
   - Search by title (case-insensitive)
   - Search by author (case-insensitive)
   - Filter by category
   - Get available books (stock > 0)

3. **Stock Management**:
   - Check stock availability
   - Validate stock for quantity
   - Reduce stock (atomic operation)
   - Increase stock (restocking)

4. **Exposed APIs**:
```
GET    /api/books               - List all books
GET    /api/books/{id}          - Get book by ID
POST   /api/books               - Create new book
PUT    /api/books/{id}          - Update book
DELETE /api/books/{id}          - Delete book
GET    /api/books/author/{name} - Search by author
GET    /api/books/title/{title} - Search by title
GET    /api/books/category/{cat}- Filter by category
GET    /api/books/available     - Get in-stock books
GET    /api/books/stock/{id}    - Check stock
POST   /api/books/{id}/validate-stock - Validate availability
PUT    /api/books/{id}/reduce-stock   - Reduce stock
PUT    /api/books/{id}/increase-stock - Increase stock
```

**Inter-service Contracts**:
- Provides book validation for payments service
- Exposes stock management for payments service
- Returns book details for payment processing

---

### 4. MS Books Payments

**Purpose**: Payment processing and order management

**Port**: 8082

**Service Name**: `ms-books-payments`

**Database**: H2 in-memory (dev) / PostgreSQL or MySQL (prod)

**Domain Model**:
```java
Payment {
  - id: Long
  - bookId: Long (FK to books catalogue)
  - bookTitle: String
  - quantity: Integer
  - unitPrice: BigDecimal
  - totalAmount: BigDecimal
  - customerName: String
  - customerEmail: String
  - status: PaymentStatus (PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED, REFUNDED)
  - paymentMethod: PaymentMethod (CREDIT_CARD, DEBIT_CARD, PAYPAL, BANK_TRANSFER, CASH)
  - transactionId: String (unique)
  - notes: String
  - createdAt: LocalDateTime
  - updatedAt: LocalDateTime
}
```

**Key Features**:

1. **Payment Processing**:
   - Multi-step payment flow
   - Transaction ID generation
   - Payment status tracking
   - Multiple payment methods

2. **Resilience Pattern** (Critical Feature):
   
   **Flow**:
   ```
   1. Validate Book Exists
      ↓ (calls ms-books-catalogue)
   2. Verify Stock Availability
      ↓ (calls ms-books-catalogue)
   3. Create Payment Record
      ↓ (status: PROCESSING)
   4. Process Payment Transaction
      ↓ (integrate with payment gateway)
   5. Update Payment Status
      ↓ (status: COMPLETED)
   6. Reduce Stock in Catalogue
      ↓ (calls ms-books-catalogue)
   7. Return Payment Confirmation
   ```

   **Error Handling**:
   - Book not found → 503 Service Unavailable
   - Insufficient stock → 400 Bad Request
   - Payment failed → Status: FAILED
   - Stock reduction failed → Status: PENDING (manual review)
   - Service unavailable → Circuit breaker fallback

3. **Circuit Breaker Integration**:
   - Uses Resilience4j
   - Protects against cascade failures
   - Fallback methods for graceful degradation
   - Configurable failure thresholds

   **Configuration**:
   ```yaml
   resilience4j:
     circuitbreaker:
       instances:
         booksService:
           slidingWindowSize: 10
           minimumNumberOfCalls: 5
           failureRateThreshold: 50
           waitDurationInOpenState: 5s
   ```

4. **Exposed APIs**:
```
GET    /api/payments                      - List all payments
GET    /api/payments/{id}                 - Get payment by ID
POST   /api/payments                      - Process new payment (MAIN)
GET    /api/payments/book/{bookId}        - Get payments for a book
GET    /api/payments/customer/{email}     - Get customer payments
GET    /api/payments/transaction/{txnId}  - Get by transaction ID
GET    /api/payments/completed            - List completed payments
PUT    /api/payments/{id}/cancel          - Cancel payment
```

**Inter-service Dependencies**:
- Depends on `ms-books-catalogue` for:
  - Book validation
  - Stock verification
  - Stock reduction

---

## Communication Patterns

### 1. Client-to-Gateway Communication
- **Protocol**: HTTP/REST
- **Format**: JSON
- **Authentication**: Not implemented (add in production)

### 2. Gateway-to-Microservices Communication
- **Discovery**: Via Eureka service names
- **Load Balancing**: Client-side (Ribbon/Spring Cloud LoadBalancer)
- **No Hardcoded URLs**: All URLs use service names

**Example**:
```java
@LoadBalanced
RestTemplate restTemplate;

// Uses service name, not IP:PORT
String url = "http://ms-books-catalogue/api/books/1";
Book book = restTemplate.getForObject(url, Book.class);
```

### 3. Microservice-to-Microservice Communication
- **Pattern**: HTTP REST (synchronous)
- **Service Discovery**: Via Eureka
- **Resilience**: Circuit breaker pattern
- **No Direct Dependencies**: Uses Eureka service names

---

## Resilience Patterns

### 1. Circuit Breaker (Resilience4j)

**Location**: MS Books Payments → MS Books Catalogue

**States**:
- **CLOSED**: Normal operation, requests flow through
- **OPEN**: Too many failures, requests blocked, fallback invoked
- **HALF_OPEN**: Testing if service recovered

**Configuration**:
```yaml
slidingWindowSize: 10              # Track last 10 calls
minimumNumberOfCalls: 5            # Need 5 calls before evaluation
failureRateThreshold: 50           # Open circuit if >50% fail
waitDurationInOpenState: 5s        # Wait 5s before half-open
```

**Fallback Methods**:
```java
@CircuitBreaker(name = "booksService", fallbackMethod = "getBookByIdFallback")
public BookDTO getBookById(Long bookId) {
    // Call to books catalogue
}

public BookDTO getBookByIdFallback(Long bookId, Exception e) {
    throw new BookServiceException("Service unavailable");
}
```

### 2. Service Discovery

**Benefits**:
- No hardcoded IPs/ports
- Dynamic service location
- Automatic load balancing
- Health-based routing

### 3. Retry Logic (Potential Enhancement)

Not currently implemented, but can be added:
```yaml
resilience4j:
  retry:
    instances:
      booksService:
        maxAttempts: 3
        waitDuration: 500ms
```

---

## Data Flow Examples

### Example 1: Successful Payment Processing

```
1. Client → Gateway
   POST /api/payments
   {
     "bookId": 2,
     "quantity": 1,
     "customerName": "Juan Pérez",
     "customerEmail": "juan@example.com",
     "paymentMethod": "CREDIT_CARD"
   }

2. Gateway → MS Books Payments
   Routes request to ms-books-payments service

3. MS Books Payments → MS Books Catalogue
   GET http://ms-books-catalogue/api/books/2
   Response: { "id": 2, "title": "...", "stock": 20, "price": 24.99 }

4. MS Books Payments → MS Books Catalogue
   POST http://ms-books-catalogue/api/books/2/validate-stock?quantity=1
   Response: true

5. MS Books Payments (Internal)
   - Creates payment record (status: PROCESSING)
   - Processes payment (simulated)
   - Updates status to COMPLETED

6. MS Books Payments → MS Books Catalogue
   PUT http://ms-books-catalogue/api/books/2/reduce-stock?quantity=1
   (Stock reduced from 20 to 19)

7. MS Books Payments → Gateway → Client
   Response:
   {
     "id": 1,
     "bookId": 2,
     "bookTitle": "Cien Años de Soledad",
     "quantity": 1,
     "unitPrice": 24.99,
     "totalAmount": 24.99,
     "status": "COMPLETED",
     "transactionId": "TXN-ABC12345"
   }
```

### Example 2: Payment Fails Due to Insufficient Stock

```
1. Client → Gateway
   POST /api/payments
   {
     "bookId": 4,
     "quantity": 999,
     ...
   }

2. Gateway → MS Books Payments
   Routes request

3. MS Books Payments → MS Books Catalogue
   GET http://ms-books-catalogue/api/books/4
   Response: { "stock": 8 }

4. MS Books Payments → MS Books Catalogue
   POST http://ms-books-catalogue/api/books/4/validate-stock?quantity=999
   Response: false

5. MS Books Payments → Gateway → Client
   HTTP 400 Bad Request
   {
     "status": 400,
     "message": "Insufficient stock. Available: 8, Requested: 999"
   }
```

### Example 3: Circuit Breaker Opens

```
1. MS Books Catalogue crashes or becomes unavailable

2. Client → Gateway → MS Books Payments
   POST /api/payments (new payment)

3. MS Books Payments → MS Books Catalogue
   Attempt to call: GET http://ms-books-catalogue/api/books/{id}
   Connection timeout/error

4. Circuit Breaker
   - Records failure
   - After 5 failures out of 10 calls (50% threshold)
   - Circuit OPENS

5. Subsequent Requests
   - Don't reach MS Books Catalogue
   - Immediately invoke fallback method
   - Return: "Books Catalogue service temporarily unavailable"

6. After 5 seconds (waitDurationInOpenState)
   - Circuit enters HALF_OPEN state
   - Next request is test request
   - If successful: Circuit CLOSES
   - If fails: Circuit stays OPEN for another 5s
```

---

## Scalability Considerations

### Horizontal Scaling

Each microservice can be scaled independently:

```bash
# Run multiple instances of Books Catalogue
java -jar ms-books-catalogue.jar --server.port=8081
java -jar ms-books-catalogue.jar --server.port=8091
java -jar ms-books-catalogue.jar --server.port=8092

# All instances register with Eureka
# Gateway load-balances across all instances automatically
```

### Database Scaling

**Development**:
- H2 in-memory (single instance)

**Production**:
- PostgreSQL/MySQL with connection pooling
- Read replicas for read-heavy operations
- Separate databases per microservice (data isolation)

---

## Security Considerations (Future Enhancements)

Currently not implemented, but recommended for production:

1. **API Gateway Security**:
   - JWT authentication
   - Rate limiting
   - IP whitelisting

2. **Inter-service Security**:
   - Mutual TLS
   - API keys
   - Service mesh (Istio)

3. **Data Security**:
   - Encrypted connections (HTTPS)
   - Database encryption at rest
   - PII protection

---

## Monitoring & Observability

### Health Checks

All services expose actuator endpoints:
```
http://localhost:8080/actuator/health  # Gateway
http://localhost:8081/actuator/health  # Books Catalogue
http://localhost:8082/actuator/health  # Payments
```

### Metrics

Available endpoints:
```
/actuator/metrics              # General metrics
/actuator/circuitbreakers      # Circuit breaker status
/actuator/circuitbreakerevents # Circuit breaker events
```

### Logging

Configured log levels:
```yaml
logging:
  level:
    com.relatosdepapel: DEBUG
    org.springframework.cloud.gateway: DEBUG
    io.github.resilience4j: DEBUG
```

---

## Deployment Architecture

### Development Environment
```
Local Machine
├── Eureka Server (8761)
├── Cloud Gateway (8080)
├── MS Books Catalogue (8081)
└── MS Books Payments (8082)
```

### Production Environment (Recommended)

```
Load Balancer
    ↓
[Gateway Cluster]
├── Gateway Instance 1
├── Gateway Instance 2
└── Gateway Instance 3
    ↓
[Eureka Cluster]
├── Eureka Instance 1
├── Eureka Instance 2
└── Eureka Instance 3
    ↓
[Microservices]
├── [Books Catalogue Cluster]
│   ├── Instance 1 + PostgreSQL Primary
│   ├── Instance 2 + PostgreSQL Read Replica
│   └── Instance 3 + PostgreSQL Read Replica
│
└── [Payments Cluster]
    ├── Instance 1 + MySQL Primary
    ├── Instance 2 + MySQL Read Replica
    └── Instance 3 + MySQL Read Replica
```

---

## Technology Stack Summary

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Spring Boot | 3.2.2 |
| Cloud | Spring Cloud | 2023.0.0 |
| Service Discovery | Netflix Eureka | Latest |
| API Gateway | Spring Cloud Gateway | Latest |
| Resilience | Resilience4j | Latest |
| Persistence | Spring Data JPA | Latest |
| Database (Dev) | H2 | Latest |
| Database (Prod) | PostgreSQL/MySQL | 14+/8+ |
| Build Tool | Maven | 3.8+ |
| Java | OpenJDK | 17+ |

---

## Design Principles

1. **Loose Coupling**: Services communicate via REST APIs
2. **High Cohesion**: Each service has a single responsibility
3. **Service Independence**: Services can be deployed independently
4. **Fault Tolerance**: Circuit breakers prevent cascade failures
5. **Scalability**: Horizontal scaling via multiple instances
6. **Observability**: Health checks and metrics for monitoring
7. **No Hardcoded Dependencies**: Service discovery via Eureka

---

## Future Enhancements

1. **Event-Driven Architecture**: Add Kafka/RabbitMQ for async communication
2. **API Versioning**: Support multiple API versions
3. **Caching**: Redis for frequently accessed data
4. **Distributed Tracing**: Sleuth + Zipkin for request tracing
5. **Centralized Configuration**: Spring Cloud Config Server
6. **Message Queue**: For decoupled communication
7. **Database per Service**: Complete data isolation
8. **Container Orchestration**: Docker + Kubernetes deployment

---

This architecture provides a solid foundation for a scalable, resilient microservices system while maintaining simplicity for educational purposes.
