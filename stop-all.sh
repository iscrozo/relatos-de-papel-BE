#!/bin/bash

###############################################################################
# Relatos de Papel - Shutdown Script
# 
# This script stops all running microservices gracefully.
#
# Usage: ./stop-all.sh
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$PROJECT_ROOT/logs"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║        RELATOS DE PAPEL - Shutdown Services              ║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to stop service by PID file
stop_service() {
    local service_name=$1
    local pid_file="$LOGS_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}Stopping ${service_name}...${NC}"
            kill $pid
            
            # Wait for graceful shutdown
            local count=0
            while ps -p $pid > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # Force kill if still running
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${YELLOW}  Force stopping ${service_name}...${NC}"
                kill -9 $pid
            fi
            
            echo -e "${GREEN}✓ ${service_name} stopped${NC}"
        else
            echo -e "${YELLOW}⚠ ${service_name} is not running${NC}"
        fi
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}⚠ No PID file found for ${service_name}${NC}"
    fi
}

# Function to stop by port
stop_by_port() {
    local service_name=$1
    local port=$2
    
    local pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "${YELLOW}Stopping ${service_name} on port ${port}...${NC}"
        kill $pid 2>/dev/null
        
        # Wait for graceful shutdown
        local count=0
        while lsof -ti:$port > /dev/null 2>&1 && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if lsof -ti:$port > /dev/null 2>&1; then
            echo -e "${YELLOW}  Force stopping ${service_name}...${NC}"
            kill -9 $pid 2>/dev/null
        fi
        
        echo -e "${GREEN}✓ ${service_name} stopped${NC}"
    fi
}

# Stop services (reverse order of startup)
echo -e "${BLUE}Stopping services...${NC}"

# Try stopping by PID files first
stop_service "cloud-gateway"
stop_service "ms-users"
stop_service "books-payments"
stop_service "books-catalogue"
stop_service "eureka-server"

# Fallback: stop by ports
echo ""
echo -e "${BLUE}Checking for any remaining processes...${NC}"
stop_by_port "Gateway" 8080
stop_by_port "Users" 8083
stop_by_port "Payments" 8082
stop_by_port "Catalogue" 8081
stop_by_port "Eureka" 8761

# Verify all ports are free
echo ""
echo -e "${BLUE}Verifying ports are free...${NC}"

ALL_STOPPED=true

if lsof -ti:8761 > /dev/null 2>&1; then
    echo -e "${RED}✗ Port 8761 (Eureka) is still in use${NC}"
    ALL_STOPPED=false
else
    echo -e "${GREEN}✓ Port 8761 is free${NC}"
fi

if lsof -ti:8080 > /dev/null 2>&1; then
    echo -e "${RED}✗ Port 8080 (Gateway) is still in use${NC}"
    ALL_STOPPED=false
else
    echo -e "${GREEN}✓ Port 8080 is free${NC}"
fi

if lsof -ti:8081 > /dev/null 2>&1; then
    echo -e "${RED}✗ Port 8081 (Books Catalogue) is still in use${NC}"
    ALL_STOPPED=false
else
    echo -e "${GREEN}✓ Port 8081 is free${NC}"
fi

if lsof -ti:8082 > /dev/null 2>&1; then
    echo -e "${RED}✗ Port 8082 (Payments) is still in use${NC}"
    ALL_STOPPED=false
else
    echo -e "${GREEN}✓ Port 8082 is free${NC}"
fi

if lsof -ti:8083 > /dev/null 2>&1; then
    echo -e "${RED}✗ Port 8083 (Users) is still in use${NC}"
    ALL_STOPPED=false
else
    echo -e "${GREEN}✓ Port 8083 is free${NC}"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
if [ "$ALL_STOPPED" = true ]; then
    echo -e "${GREEN}✓ All services stopped successfully!${NC}"
else
    echo -e "${RED}✗ Some services may still be running${NC}"
    echo -e "${YELLOW}  Try running: lsof -ti:PORT | xargs kill -9${NC}"
fi
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

# Clean up logs (optional)
if [ "$1" = "--clean-logs" ]; then
    echo ""
    echo -e "${YELLOW}Cleaning up log files...${NC}"
    rm -rf "$LOGS_DIR"/*
    echo -e "${GREEN}✓ Logs cleaned${NC}"
fi

echo ""
echo -e "${BLUE}To start services again: ./start-all.sh${NC}"
