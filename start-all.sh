#!/bin/bash

###############################################################################
# Relatos de Papel - Startup Script
# 
# This script starts all microservices in the correct order with proper
# wait times for service registration.
#
# Usage: ./start-all.sh
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║        RELATOS DE PAPEL - Microservices Startup          ║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to wait for service health
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    echo -e "${YELLOW}Waiting for ${service_name} to be healthy...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "http://localhost:${port}/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ ${service_name} is healthy!${NC}"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo -e "${RED}✗ ${service_name} failed to start within expected time${NC}"
    return 1
}

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}✗ Port ${port} is already in use!${NC}"
        echo -e "${YELLOW}  Please stop the process using this port and try again.${NC}"
        return 1
    fi
    return 0
}

# Check prerequisites
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java is not installed!${NC}"
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    echo -e "${RED}✗ Maven is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Java and Maven found${NC}"

# Check if all ports are available
echo -e "${BLUE}[2/5] Checking port availability...${NC}"
check_port 8761 || exit 1
check_port 8080 || exit 1
check_port 8081 || exit 1
check_port 8082 || exit 1
check_port 8083 || exit 1
echo -e "${GREEN}✓ All ports are available${NC}"

# Build all modules
echo -e "${BLUE}[3/5] Building all modules...${NC}"
cd "$PROJECT_ROOT"
mvn clean install -DskipTests -q
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Start Eureka Server
echo -e "${BLUE}[4/5] Starting services...${NC}"
echo -e "${YELLOW}Starting Eureka Server (Port 8761)...${NC}"
cd "$PROJECT_ROOT/eureka-server"
nohup mvn spring-boot:run > "$PROJECT_ROOT/logs/eureka-server.log" 2>&1 &
EUREKA_PID=$!
echo $EUREKA_PID > "$PROJECT_ROOT/logs/eureka-server.pid"

# Wait for Eureka to be healthy
wait_for_service "Eureka Server" 8761
sleep 5

# Start Books Catalogue
echo -e "${YELLOW}Starting Books Catalogue (Port 8081)...${NC}"
cd "$PROJECT_ROOT/ms-books-catalogue"
nohup mvn spring-boot:run > "$PROJECT_ROOT/logs/books-catalogue.log" 2>&1 &
CATALOGUE_PID=$!
echo $CATALOGUE_PID > "$PROJECT_ROOT/logs/books-catalogue.pid"

# Wait for registration
wait_for_service "Books Catalogue" 8081
sleep 5

# Start Payments Service
echo -e "${YELLOW}Starting Payments Service (Port 8082)...${NC}"
cd "$PROJECT_ROOT/ms-books-payments"
nohup mvn spring-boot:run > "$PROJECT_ROOT/logs/books-payments.log" 2>&1 &
PAYMENTS_PID=$!
echo $PAYMENTS_PID > "$PROJECT_ROOT/logs/books-payments.pid"

# Wait for registration
wait_for_service "Payments Service" 8082
sleep 5

# Start Users Service
echo -e "${YELLOW}Starting Users Service (Port 8083)...${NC}"
cd "$PROJECT_ROOT/ms-users"
nohup mvn spring-boot:run > "$PROJECT_ROOT/logs/ms-users.log" 2>&1 &
USERS_PID=$!
echo $USERS_PID > "$PROJECT_ROOT/logs/ms-users.pid"

# Wait for registration
wait_for_service "Users Service" 8083
sleep 5

# Start Gateway
echo -e "${YELLOW}Starting Cloud Gateway (Port 8080)...${NC}"
cd "$PROJECT_ROOT/cloud-gateway"
nohup mvn spring-boot:run > "$PROJECT_ROOT/logs/cloud-gateway.log" 2>&1 &
GATEWAY_PID=$!
echo $GATEWAY_PID > "$PROJECT_ROOT/logs/cloud-gateway.pid"

# Wait for registration
wait_for_service "Cloud Gateway" 8080
sleep 5

# Verify all services
echo -e "${BLUE}[5/5] Verifying system health...${NC}"

ALL_HEALTHY=true

if ! curl -s http://localhost:8761/actuator/health | grep -q "UP"; then
    echo -e "${RED}✗ Eureka Server is not healthy${NC}"
    ALL_HEALTHY=false
else
    echo -e "${GREEN}✓ Eureka Server: UP${NC}"
fi

if ! curl -s http://localhost:8081/actuator/health | grep -q "UP"; then
    echo -e "${RED}✗ Books Catalogue is not healthy${NC}"
    ALL_HEALTHY=false
else
    echo -e "${GREEN}✓ Books Catalogue: UP${NC}"
fi

if ! curl -s http://localhost:8082/actuator/health | grep -q "UP"; then
    echo -e "${RED}✗ Payments Service is not healthy${NC}"
    ALL_HEALTHY=false
else
    echo -e "${GREEN}✓ Payments Service: UP${NC}"
fi

if ! curl -s http://localhost:8083/actuator/health | grep -q "UP"; then
    echo -e "${RED}✗ Users Service is not healthy${NC}"
    ALL_HEALTHY=false
else
    echo -e "${GREEN}✓ Users Service: UP${NC}"
fi

if ! curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
    echo -e "${RED}✗ Cloud Gateway is not healthy${NC}"
    ALL_HEALTHY=false
else
    echo -e "${GREEN}✓ Cloud Gateway: UP${NC}"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   SYSTEM STATUS                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}✓ All services are running successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Available URLs:${NC}"
    echo -e "  • Eureka Dashboard:   ${BLUE}http://localhost:8761${NC}"
    echo -e "  • Gateway (API):      ${BLUE}http://localhost:8080${NC}"
    echo -e "  • Books API:          ${BLUE}http://localhost:8080/api/books${NC}"
    echo -e "  • Payments API:       ${BLUE}http://localhost:8080/api/payments${NC}"
    echo -e "  • Auth API:           ${BLUE}http://localhost:8080/api/auth${NC}"
    echo -e "  • Books H2 Console:   ${BLUE}http://localhost:8081/h2-console${NC}"
    echo -e "  • Payments H2 Console:${BLUE}http://localhost:8082/h2-console${NC}"
    echo -e "  • Users H2 Console:   ${BLUE}http://localhost:8083/h2-console${NC}"
    echo ""
    echo -e "${YELLOW}Logs directory:${NC} $PROJECT_ROOT/logs"
    echo -e "${YELLOW}To stop all services:${NC} ./stop-all.sh"
    echo ""
    echo -e "${GREEN}Quick test:${NC}"
    echo -e "  curl http://localhost:8080/api/books"
else
    echo -e "${RED}✗ Some services failed to start properly${NC}"
    echo -e "${YELLOW}Check logs in: $PROJECT_ROOT/logs${NC}"
    exit 1
fi
