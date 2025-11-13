#!/bin/bash
# Quick midPoint health check script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MIDPOINT_CONTAINER="mp-grouper-podman-midpoint_server-1"
POSTGRES_CONTAINER="mp-grouper-podman-midpoint_data-1"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  midPoint Quick Health Check${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# Check containers
echo -e "${YELLOW}Container Status:${NC}"
if docker ps --filter "name=${MIDPOINT_CONTAINER}" --format "{{.Status}}" | grep -q "Up"; then
    STATUS=$(docker ps --filter "name=${MIDPOINT_CONTAINER}" --format "{{.Status}}")
    echo -e "  midPoint: ${GREEN}✓ ${STATUS}${NC}"
else
    echo -e "  midPoint: ${RED}✗ NOT RUNNING${NC}"
fi

if docker ps --filter "name=${POSTGRES_CONTAINER}" --format "{{.Status}}" | grep -q "Up"; then
    STATUS=$(docker ps --filter "name=${POSTGRES_CONTAINER}" --format "{{.Status}}")
    echo -e "  PostgreSQL: ${GREEN}✓ ${STATUS}${NC}"
else
    echo -e "  PostgreSQL: ${RED}✗ NOT RUNNING${NC}"
fi

echo ""
echo -e "${YELLOW}Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
    ${MIDPOINT_CONTAINER} ${POSTGRES_CONTAINER} 2>/dev/null

echo ""
echo -e "${YELLOW}Health Check:${NC}"
HEALTH=$(curl -s http://localhost:8080/midpoint/actuator/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo -e "  Health endpoint: ${GREEN}✓ UP${NC}"
else
    echo -e "  Health endpoint: ${RED}✗ DOWN or unreachable${NC}"
fi

echo ""
echo -e "${YELLOW}Recent Errors (last 5):${NC}"
ERROR_COUNT=$(docker logs --tail 100 ${MIDPOINT_CONTAINER} 2>/dev/null | grep -c "ERROR")
echo -e "  Error count in last 100 lines: ${RED}${ERROR_COUNT}${NC}"

if [ $ERROR_COUNT -gt 0 ]; then
    docker logs --tail 100 ${MIDPOINT_CONTAINER} 2>/dev/null | grep "ERROR" | tail -5 | \
        sed 's/^/    /' | cut -c1-120
fi

echo ""
echo -e "${BLUE}==================================${NC}"
