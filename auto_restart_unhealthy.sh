#!/bin/bash
#
# Auto-Restart Unhealthy Containers
# Monitors Docker containers and restarts them if they become unhealthy
#
# Usage:
#   ./auto_restart_unhealthy.sh              # Check once and exit
#   ./auto_restart_unhealthy.sh --daemon     # Run continuously (60s interval)
#   ./auto_restart_unhealthy.sh --interval 30 # Custom interval
#
# Compatible with Bash 3.2+ (macOS default)
#

set -eo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/container_restart.log"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
RESTART_DIR="${SCRIPT_DIR}/.restart_tracking"
CHECK_INTERVAL=60
DAEMON_MODE=false
MAX_RESTARTS_PER_HOUR=3
RESTART_COOLDOWN=300  # 5 minutes between restarts

# Containers to monitor (leave empty to monitor all)
MONITORED_CONTAINERS=(
    "mp-grouper-podman-midpoint_server-1"
    "mp-grouper-podman-midpoint_data-1"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create restart tracking directory
mkdir -p "$RESTART_DIR"

# Log function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    log "WARN" "$@"
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}[ERROR]${NC} $*"
}

log_success() {
    log "SUCCESS" "$@"
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Get last restart timestamp for container
get_last_restart_time() {
    local container="$1"
    local ts_file="${RESTART_DIR}/${container}.last"

    if [ -f "$ts_file" ]; then
        cat "$ts_file"
    else
        echo "0"
    fi
}

# Set last restart timestamp
set_last_restart_time() {
    local container="$1"
    local timestamp="$2"
    local ts_file="${RESTART_DIR}/${container}.last"

    echo "$timestamp" > "$ts_file"
}

# Check if container was recently restarted
check_restart_cooldown() {
    local container="$1"
    local now
    now=$(date +%s)
    local last_restart
    last_restart=$(get_last_restart_time "$container")

    if [ "$last_restart" -gt 0 ]; then
        local time_since_restart=$((now - last_restart))

        if [ "$time_since_restart" -lt "$RESTART_COOLDOWN" ]; then
            local wait_time=$((RESTART_COOLDOWN - time_since_restart))
            log_warn "Container $container was restarted ${time_since_restart}s ago. Waiting ${wait_time}s before next restart."
            return 1
        fi
    fi

    return 0
}

# Count restarts in last hour
count_recent_restarts() {
    local container="$1"
    local now
    now=$(date +%s)
    local one_hour_ago=$((now - 3600))
    local history_file="${RESTART_DIR}/${container}.history"

    local count=0

    if [ -f "$history_file" ]; then
        while IFS= read -r timestamp; do
            if [ "$timestamp" -gt "$one_hour_ago" ]; then
                count=$((count + 1))
            fi
        done < "$history_file"
    fi

    echo "$count"
}

# Record restart
record_restart() {
    local container="$1"
    local now
    now=$(date +%s)

    # Update last restart time
    set_last_restart_time "$container" "$now"

    # Add to history
    local history_file="${RESTART_DIR}/${container}.history"
    echo "$now" >> "$history_file"

    # Clean old entries (older than 1 hour)
    local one_hour_ago=$((now - 3600))
    local temp_file="${history_file}.tmp"

    if [ -f "$history_file" ]; then
        awk -v cutoff="$one_hour_ago" '$1 > cutoff' "$history_file" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$history_file" 2>/dev/null || true
    fi
}

# Get container status
get_container_status() {
    local container="$1"
    docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found"
}

# Get container health
get_container_health() {
    local container="$1"
    docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || echo "unknown"
}

# Check if container is responsive
check_container_responsive() {
    local container="$1"

    # For midPoint, check if web interface is accessible
    if echo "$container" | grep -q "midpoint_server"; then
        if curl -s -f -m 5 "http://localhost:8080/midpoint/actuator/health" > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi

    # For PostgreSQL, check if it accepts connections
    if echo "$container" | grep -q -E "midpoint_data|postgres"; then
        if docker exec "$container" pg_isready -U midpoint > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi

    # Default: assume responsive if running
    return 0
}

# Restart container
restart_container() {
    local container="$1"
    local reason="$2"

    log_warn "Container $container needs restart: $reason"

    # Check cooldown
    if ! check_restart_cooldown "$container"; then
        return 1
    fi

    # Check restart rate limit
    local restart_count
    restart_count=$(count_recent_restarts "$container")

    if [ "$restart_count" -ge "$MAX_RESTARTS_PER_HOUR" ]; then
        log_error "Container $container has been restarted $restart_count times in the last hour. Rate limit exceeded!"
        log_error "Manual intervention required. Check logs: docker logs $container"
        return 1
    fi

    log_info "Attempting to restart $container (restart #$((restart_count + 1)) this hour)..."

    # Try docker-compose restart first if compose file exists
    if [ -f "$COMPOSE_FILE" ]; then
        local service_name
        service_name=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.service"}}' "$container" 2>/dev/null || echo "")

        if [ -n "$service_name" ]; then
            if docker-compose -f "$COMPOSE_FILE" restart "$service_name" >> "$LOG_FILE" 2>&1; then
                log_success "Container $container restarted successfully via docker-compose"
                record_restart "$container"
                return 0
            fi
        fi
    fi

    # Fallback to direct docker restart
    if docker restart "$container" >> "$LOG_FILE" 2>&1; then
        log_success "Container $container restarted successfully"
        record_restart "$container"
        return 0
    else
        log_error "Failed to restart container $container"
        return 1
    fi
}

# Check single container
check_container() {
    local container="$1"

    local status
    status=$(get_container_status "$container")

    if [ "$status" = "not_found" ]; then
        log_warn "Container $container not found"
        return 1
    fi

    # Check if container is stopped
    if [ "$status" != "running" ]; then
        restart_container "$container" "Container is not running (status: $status)"
        return $?
    fi

    # Check health status
    local health
    health=$(get_container_health "$container")

    if [ "$health" = "unhealthy" ]; then
        restart_container "$container" "Health check failed (status: unhealthy)"
        return $?
    fi

    # Additional responsiveness check for critical services
    if ! check_container_responsive "$container"; then
        log_warn "Container $container is not responsive"
        restart_container "$container" "Container not responding to health checks"
        return $?
    fi

    log_info "Container $container is healthy (status: $status, health: $health)"
    return 0
}

# Check all monitored containers
check_all_containers() {
    log_info "Starting health check cycle..."

    local containers_to_check=()

    if [ ${#MONITORED_CONTAINERS[@]} -eq 0 ]; then
        # Monitor all running containers
        while IFS= read -r container; do
            containers_to_check+=("$container")
        done < <(docker ps --format '{{.Names}}')
    else
        containers_to_check=("${MONITORED_CONTAINERS[@]}")
    fi

    local total=0
    local healthy=0
    local restarted=0
    local failed=0

    for container in "${containers_to_check[@]}"; do
        total=$((total + 1))
        if check_container "$container"; then
            healthy=$((healthy + 1))
        else
            if docker inspect "$container" > /dev/null 2>&1; then
                restarted=$((restarted + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done

    log_info "Health check complete: $total containers checked, $healthy healthy, $restarted restarted, $failed failed"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
            --daemon|-d)
                DAEMON_MODE=true
                shift
                ;;
            --interval|-i)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --daemon, -d           Run in daemon mode (continuous monitoring)"
                echo "  --interval, -i SECS    Check interval in seconds (default: 60)"
                echo "  --help, -h             Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                     # Run once"
                echo "  $0 --daemon            # Run continuously"
                echo "  $0 --daemon -i 30      # Check every 30 seconds"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Cleanup function
cleanup() {
    log_info "Shutting down container health monitor..."
    exit 0
}

# Main function
main() {
    parse_args "$@"

    log_info "=== Container Health Monitor Started ==="
    log_info "Log file: $LOG_FILE"
    log_info "Monitoring containers: ${MONITORED_CONTAINERS[*]:-all containers}"
    log_info "Check interval: ${CHECK_INTERVAL}s"
    log_info "Max restarts per hour: $MAX_RESTARTS_PER_HOUR"
    log_info "Restart cooldown: ${RESTART_COOLDOWN}s"
    echo ""

    # Setup signal handlers
    trap cleanup SIGINT SIGTERM

    if [ "$DAEMON_MODE" = true ]; then
        log_info "Running in daemon mode. Press Ctrl+C to stop."
        echo ""

        while true; do
            check_all_containers
            log_info "Waiting ${CHECK_INTERVAL}s until next check..."
            sleep "$CHECK_INTERVAL"
        done
    else
        check_all_containers
        log_info "Single check complete. Use --daemon for continuous monitoring."
    fi
}

# Run main function
main "$@"
