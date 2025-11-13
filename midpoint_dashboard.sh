#!/bin/bash
# Live monitoring dashboard for midPoint

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

MIDPOINT_CONTAINER="mp-grouper-podman-midpoint_server-1"
POSTGRES_CONTAINER="mp-grouper-podman-midpoint_data-1"
REFRESH_INTERVAL=${1:-5}  # Default 5 seconds, can be overridden

# Clear screen and hide cursor
clear
tput civis

# Cleanup on exit
cleanup() {
    tput cnorm  # Show cursor
    echo -e "\n${YELLOW}Dashboard stopped${NC}"
    exit 0
}

trap cleanup INT TERM

echo -e "${CYAN}${BOLD}Starting midPoint Live Dashboard (refresh: ${REFRESH_INTERVAL}s)${NC}"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}\n"
sleep 2

while true; do
    clear
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║            midPoint Live Monitoring Dashboard                      ║${NC}"
    echo -e "${CYAN}${BOLD}║            ${TIMESTAMP}                              ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════╝${NC}"

    # Container Status
    echo -e "\n${BOLD}${BLUE}━━━ CONTAINER STATUS ━━━${NC}"

    MP_STATUS=$(docker inspect ${MIDPOINT_CONTAINER} 2>/dev/null | jq -r '.[0].State.Status' 2>/dev/null)
    MP_HEALTH=$(docker inspect ${MIDPOINT_CONTAINER} 2>/dev/null | jq -r '.[0].State.Health.Status // "N/A"' 2>/dev/null)
    PG_STATUS=$(docker inspect ${POSTGRES_CONTAINER} 2>/dev/null | jq -r '.[0].State.Status' 2>/dev/null)

    if [ "$MP_STATUS" == "running" ]; then
        if [ "$MP_HEALTH" == "healthy" ]; then
            echo -e "  ${GREEN}●${NC} midPoint Server: ${GREEN}Running (${MP_HEALTH})${NC}"
        else
            echo -e "  ${YELLOW}●${NC} midPoint Server: ${YELLOW}Running (${MP_HEALTH})${NC}"
        fi
    else
        echo -e "  ${RED}●${NC} midPoint Server: ${RED}${MP_STATUS}${NC}"
    fi

    if [ "$PG_STATUS" == "running" ]; then
        echo -e "  ${GREEN}●${NC} PostgreSQL: ${GREEN}Running${NC}"
    else
        echo -e "  ${RED}●${NC} PostgreSQL: ${RED}${PG_STATUS}${NC}"
    fi

    # Resource Usage
    echo -e "\n${BOLD}${BLUE}━━━ RESOURCE USAGE ━━━${NC}"
    docker stats --no-stream --format "  {{.Name}}: CPU ${BOLD}{{.CPUPerc}}${NC} | MEM ${BOLD}{{.MemPerc}}${NC} ({{.MemUsage}}) | PIDs {{.PIDs}}" \
        ${MIDPOINT_CONTAINER} ${POSTGRES_CONTAINER} 2>/dev/null | sed "s/${MIDPOINT_CONTAINER}/midPoint/" | sed "s/${POSTGRES_CONTAINER}/PostgreSQL/"

    # Application Health
    echo -e "\n${BOLD}${BLUE}━━━ APPLICATION HEALTH ━━━${NC}"

    HEALTH=$(curl -s -m 3 http://localhost:8080/midpoint/actuator/health 2>/dev/null)
    if echo "$HEALTH" | grep -q '"status":"UP"'; then
        echo -e "  ${GREEN}✓${NC} Health Endpoint: ${GREEN}UP${NC}"
    else
        echo -e "  ${RED}✗${NC} Health Endpoint: ${RED}DOWN or unreachable${NC}"
    fi

    WEB=$(curl -s -I -m 3 http://localhost:8080/midpoint/ 2>/dev/null | head -1)
    if echo "$WEB" | grep -q "HTTP.*[23]0[0-9]"; then
        echo -e "  ${GREEN}✓${NC} Web Interface: ${GREEN}Accessible${NC}"
    else
        echo -e "  ${RED}✗${NC} Web Interface: ${RED}Not accessible${NC}"
    fi

    # Error Statistics
    echo -e "\n${BOLD}${BLUE}━━━ ERROR STATISTICS (last 200 log lines) ━━━${NC}"

    ERROR_COUNT=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep -c "ERROR")
    WARN_COUNT=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep -c "WARN")

    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "  ${RED}Errors: ${ERROR_COUNT}${NC}"
    else
        echo -e "  ${GREEN}Errors: 0${NC}"
    fi

    if [ "$WARN_COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}Warnings: ${WARN_COUNT}${NC}"
    else
        echo -e "  ${GREEN}Warnings: 0${NC}"
    fi

    # Reconciliation Status
    RECON_ERRORS=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep -c "Reconciliation.*ERROR")
    RECON_COMPLETE=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep -c "Reconciliation.*Completed")

    echo -e "\n${BOLD}${BLUE}━━━ RECONCILIATION STATUS ━━━${NC}"

    if [ "$RECON_ERRORS" -gt 0 ]; then
        echo -e "  ${RED}Recent Errors: ${RECON_ERRORS}${NC}"
        AFFECTED_RESOURCE=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep "Reconciliation.*ERROR" | grep -o "resource:[^(]*([^)]*)" | head -1 | sed 's/resource:[^(]*(//' | sed 's/)//')
        if [ -n "$AFFECTED_RESOURCE" ]; then
            echo -e "  ${YELLOW}Affected: ${AFFECTED_RESOURCE}${NC}"
        fi
    else
        echo -e "  ${GREEN}No recent errors${NC}"
    fi

    echo -e "  Completed: ${RECON_COMPLETE}"

    # Latest Error (if any)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "\n${BOLD}${BLUE}━━━ LATEST ERROR ━━━${NC}"
        LATEST_ERROR=$(docker logs --tail 200 ${MIDPOINT_CONTAINER} 2>/dev/null | grep "ERROR" | tail -1 | cut -c1-120)
        echo -e "  ${RED}${LATEST_ERROR}...${NC}"
    fi

    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Refreshing in ${REFRESH_INTERVAL}s... (Press Ctrl+C to exit)${NC}"

    sleep $REFRESH_INTERVAL
done
