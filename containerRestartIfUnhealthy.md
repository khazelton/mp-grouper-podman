containerRestartIfUnhealthy.adoc

  Current Status: Your midPoint system is now error-free and fully operational! 🎉

> /cost
  ⎿  With your Claude Max subscription, no need to monitor cost — your subscription includes Claude Code usage

> /context
  ⎿
      Context Usage
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛀ ⛁ ⛁   claude-sonnet-4-5-20250929 · 153k/200k tokens (77%)
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ System prompt: 2.8k tokens (1.4%)
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ System tools: 13.4k tokens (6.7%)
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ Messages: 92.2k tokens (46.1%)
     ⛁ ⛁ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛶ Free space: 47k (23.3%)
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛝ Autocompact buffer: 45.0k tokens (22.5%)
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛝ ⛝ ⛝
     ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝
     ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝

     SlashCommand Tool · 0 commands
     └ Total: 864 tokens



> Create a script to restart containers if they become unhealthy

⏺ I'll create a script to automatically restart containers if they become unhealthy.

⏺ Write(auto_restart_unhealthy.sh)
  ⎿  Wrote 363 lines to auto_restart_unhealthy.sh
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
     … +353 lines (ctrl+o to expand)

⏺ Bash(chmod +x /Users/kh/opt/mp-grouper-podman/auto_restart_unhealthy.sh)
  ⎿

⏺ Write(container-health.service)
  ⎿  Wrote 36 lines to container-health.service
     # Systemd service file for container health monitoring
     # Install to: /etc/systemd/system/container-health.service
     #
     # Installation:
     #   sudo cp container-health.service /etc/systemd/system/
     #   sudo systemctl daemon-reload
     #   sudo systemctl enable container-health.service
     #   sudo systemctl start container-health.service
     #
     # Check status:
     … +26 lines (ctrl+o to expand)

⏺ Write(AUTO_RESTART_README.md)
  ⎿  Wrote 381 lines to AUTO_RESTART_README.md
     # Container Auto-Restart Documentation
     **Created:** November 12, 2025
     ## Overview
     Automated health monitoring and restart script for Docker containers. Prevents extended downtime by automatically
     restarting unhealthy containers while preventing restart loops.
     ## Features
     … +371 lines (ctrl+o to expand)

⏺ Now let me test the script to verify it works:

⏺ Bash(./auto_restart_unhealthy.sh --help)
  ⎿  Error: Exit code 2
     ./auto_restart_unhealthy.sh: line 67: declare: -A: invalid option
     declare: usage: declare [-afFirtx] [-p] [name[=value] ...]



⏺ Update(auto_restart_unhealthy.sh)
  ⎿  Updated auto_restart_unhealthy.sh with 14 additions and 1 removal
       1 -  #!/bin/bash
       1 +  #!/usr/bin/env bash
       2    #
       3    # Auto-Restart Unhealthy Containers
       4    # Monitors Docker containers and restarts them if they become unhealthy
     ...
        8    #   ./auto_restart_unhealthy.sh --daemon     # Run continuously (60s interval)
        9    #   ./auto_restart_unhealthy.sh --interval 30 # Custom interval
       10    #
       11 +  # Requirements: Bash 4.0+ (for associative arrays)
       12 +  # macOS users: Install with `brew install bash` and use /usr/local/bin/bash
       13 +  #
       14
       15    set -euo pipefail
       16
       17 +  # Check bash version
       18 +  if ((BASH_VERSINFO[0] < 4)); then
       19 +      echo "Error: This script requires Bash 4.0 or higher"
       20 +      echo "Current version: $BASH_VERSION"
       21 +      echo ""
       22 +      echo "On macOS, install with: brew install bash"
       23 +      echo "Then run with: /usr/local/bin/bash $0"
       24 +      exit 1
       25 +  fi
       26 +
       27    # Configuration
       28    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
       29    LOG_FILE="${SCRIPT_DIR}/container_restart.log"

⏺ Bash(which bash)
  ⎿

⏺ Bash(bash --version)
  ⎿  GNU bash, version 3.2.57(1)-release (arm64-apple-darwin24)
     Copyright (C) 2007 Free Software Foundation, Inc.

⏺ Bash(if [ -f /opt/homebrew/bin/bash ]; then /opt/homebrew/bin/bash --version | head -1; elif [ -f /usr/local/bin/bash ];
      then /usr/local/bin/bash --version | head -1…)
  ⎿  Homebrew bash not found

⏺ Write(auto_restart_unhealthy.sh)
  ⎿  Updated auto_restart_unhealthy.sh with 66 additions and 50 removals
       1 -  #!/usr/bin/env bash
       1 +  #!/bin/bash
       2    #
       3    # Auto-Restart Unhealthy Containers
       4    # Monitors Docker containers and restarts them if they become unhealthy
     ...
        8    #   ./auto_restart_unhealthy.sh --daemon     # Run continuously (60s interval)
        9    #   ./auto_restart_unhealthy.sh --interval 30 # Custom interval
       10    #
       11 -  # Requirements: Bash 4.0+ (for associative arrays)
       12 -  # macOS users: Install with `brew install bash` and use /usr/local/bin/bash
       11 +  # Compatible with Bash 3.2+ (macOS default)
       12    #
       13
       14 -  set -euo pipefail
       14 +  set -eo pipefail
       15
       16 -  # Check bash version
       17 -  if ((BASH_VERSINFO[0] < 4)); then
       18 -      echo "Error: This script requires Bash 4.0 or higher"
       19 -      echo "Current version: $BASH_VERSION"
       20 -      echo ""
       21 -      echo "On macOS, install with: brew install bash"
       22 -      echo "Then run with: /usr/local/bin/bash $0"
       23 -      exit 1
       24 -  fi
       25 -
       16    # Configuration
       17 -  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
       17 +  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
       18    LOG_FILE="${SCRIPT_DIR}/container_restart.log"
       19    COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
       20 +  RESTART_DIR="${SCRIPT_DIR}/.restart_tracking"
       21    CHECK_INTERVAL=60
       22    DAEMON_MODE=false
       23    MAX_RESTARTS_PER_HOUR=3
     ...
       46    BLUE='\033[0;34m'
       47    NC='\033[0m' # No Color
       48
       49 +  # Create restart tracking directory
       50 +  mkdir -p "$RESTART_DIR"
       51 +
       52    # Log function
       53    log() {
       54        local level="$1"
     ...
        76        echo -e "${GREEN}[SUCCESS]${NC} $*"
        77    }
        78
        79 -  # Track restart history
        80 -  declare -A RESTART_TIMESTAMPS
        79 +  # Get last restart timestamp for container
        80 +  get_last_restart_time() {
        81 +      local container="$1"
        82 +      local ts_file="${RESTART_DIR}/${container}.last"
        83
        84 +      if [ -f "$ts_file" ]; then
        85 +          cat "$ts_file"
        86 +      else
        87 +          echo "0"
        88 +      fi
        89 +  }
        90 +
        91 +  # Set last restart timestamp
        92 +  set_last_restart_time() {
        93 +      local container="$1"
        94 +      local timestamp="$2"
        95 +      local ts_file="${RESTART_DIR}/${container}.last"
        96 +
        97 +      echo "$timestamp" > "$ts_file"
        98 +  }
        99 +
       100    # Check if container was recently restarted
       101    check_restart_cooldown() {
       102        local container="$1"
       103        local now
       104        now=$(date +%s)
       105 +      local last_restart
       106 +      last_restart=$(get_last_restart_time "$container")
       107
       108 -      if [[ -n "${RESTART_TIMESTAMPS[$container]:-}" ]]; then
       109 -          local last_restart="${RESTART_TIMESTAMPS[$container]}"
       108 +      if [ "$last_restart" -gt 0 ]; then
       109            local time_since_restart=$((now - last_restart))
       110
       111 -          if [[ $time_since_restart -lt $RESTART_COOLDOWN ]]; then
       111 +          if [ "$time_since_restart" -lt "$RESTART_COOLDOWN" ]; then
       112                local wait_time=$((RESTART_COOLDOWN - time_since_restart))
       113                log_warn "Container $container was restarted ${time_since_restart}s ago. Waiting
             ${wait_time}s before next restart."
       114                return 1
     ...
       105        local now
       106        now=$(date +%s)
       107        local one_hour_ago=$((now - 3600))
       108 +      local history_file="${RESTART_DIR}/${container}.history"
       109
       110        local count=0
       111 -      local timestamps_file="${SCRIPT_DIR}/.restart_history_${container}"
       111
       112 -      if [[ -f "$timestamps_file" ]]; then
       112 +      if [ -f "$history_file" ]; then
       113            while IFS= read -r timestamp; do
       114 -              if [[ $timestamp -gt $one_hour_ago ]]; then
       115 -                  ((count++))
       114 +              if [ "$timestamp" -gt "$one_hour_ago" ]; then
       115 +                  count=$((count + 1))
       116                fi
       117 -          done < "$timestamps_file"
       117 +          done < "$history_file"
       118        fi
       119
       120        echo "$count"
     ...
       126        local now
       127        now=$(date +%s)
       128
       129 -      RESTART_TIMESTAMPS[$container]=$now
       129 +      # Update last restart time
       130 +      set_last_restart_time "$container" "$now"
       131
       132 -      local timestamps_file="${SCRIPT_DIR}/.restart_history_${container}"
       133 -      echo "$now" >> "$timestamps_file"
       132 +      # Add to history
       133 +      local history_file="${RESTART_DIR}/${container}.history"
       134 +      echo "$now" >> "$history_file"
       135
       136        # Clean old entries (older than 1 hour)
       137        local one_hour_ago=$((now - 3600))
       138 -      local temp_file="${timestamps_file}.tmp"
       138 +      local temp_file="${history_file}.tmp"
       139
       140 -      if [[ -f "$timestamps_file" ]]; then
       141 -          awk -v cutoff="$one_hour_ago" '$1 > cutoff' "$timestamps_file" > "$temp_file" || true
       142 -          mv "$temp_file" "$timestamps_file"
       140 +      if [ -f "$history_file" ]; then
       141 +          awk -v cutoff="$one_hour_ago" '$1 > cutoff' "$history_file" > "$temp_file" 2>/dev/null || true
       142 +          mv "$temp_file" "$history_file" 2>/dev/null || true
       143        fi
       144    }
       145
     ...
       158        local container="$1"
       159
       160        # For midPoint, check if web interface is accessible
       161 -      if [[ "$container" == *"midpoint_server"* ]]; then
       161 +      if echo "$container" | grep -q "midpoint_server"; then
       162            if curl -s -f -m 5 "http://localhost:8080/midpoint/actuator/health" > /dev/null 2>&1; then
       163                return 0
       164            else
     ...
       167        fi
       168
       169        # For PostgreSQL, check if it accepts connections
       170 -      if [[ "$container" == *"midpoint_data"* ]] || [[ "$container" == *"postgres"* ]]; then
       170 +      if echo "$container" | grep -q -E "midpoint_data|postgres"; then
       171            if docker exec "$container" pg_isready -U midpoint > /dev/null 2>&1; then
       172                return 0
       173            else
     ...
       195        local restart_count
       196        restart_count=$(count_recent_restarts "$container")
       197
       198 -      if [[ $restart_count -ge $MAX_RESTARTS_PER_HOUR ]]; then
       198 +      if [ "$restart_count" -ge "$MAX_RESTARTS_PER_HOUR" ]; then
       199            log_error "Container $container has been restarted $restart_count times in the last hour. Rate
             limit exceeded!"
       200            log_error "Manual intervention required. Check logs: docker logs $container"
       201            return 1
     ...
       204        log_info "Attempting to restart $container (restart #$((restart_count + 1)) this hour)..."
       205
       206        # Try docker-compose restart first if compose file exists
       207 -      if [[ -f "$COMPOSE_FILE" ]]; then
       207 +      if [ -f "$COMPOSE_FILE" ]; then
       208            local service_name
       209            service_name=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.service"}}'
             "$container" 2>/dev/null || echo "")
       210
       211 -          if [[ -n "$service_name" ]]; then
       212 -              if docker-compose -f "$COMPOSE_FILE" restart "$service_name" 2>&1 | tee -a "$LOG_FILE"; then
       211 +          if [ -n "$service_name" ]; then
       212 +              if docker-compose -f "$COMPOSE_FILE" restart "$service_name" >> "$LOG_FILE" 2>&1; then
       213                    log_success "Container $container restarted successfully via docker-compose"
       214                    record_restart "$container"
       215                    return 0
     ...
       218        fi
       219
       220        # Fallback to direct docker restart
       221 -      if docker restart "$container" 2>&1 | tee -a "$LOG_FILE"; then
       221 +      if docker restart "$container" >> "$LOG_FILE" 2>&1; then
       222            log_success "Container $container restarted successfully"
       223            record_restart "$container"
       224            return 0
     ...
       235        local status
       236        status=$(get_container_status "$container")
       237
       238 -      if [[ "$status" == "not_found" ]]; then
       238 +      if [ "$status" = "not_found" ]; then
       239            log_warn "Container $container not found"
       240            return 1
       241        fi
       242
       243        # Check if container is stopped
       244 -      if [[ "$status" != "running" ]]; then
       244 +      if [ "$status" != "running" ]; then
       245            restart_container "$container" "Container is not running (status: $status)"
       246            return $?
       247        fi
     ...
       250        local health
       251        health=$(get_container_health "$container")
       252
       253 -      if [[ "$health" == "unhealthy" ]]; then
       253 +      if [ "$health" = "unhealthy" ]; then
       254            restart_container "$container" "Health check failed (status: unhealthy)"
       255            return $?
       256        fi
     ...
       272
       273        local containers_to_check=()
       274
       275 -      if [[ ${#MONITORED_CONTAINERS[@]} -eq 0 ]]; then
       275 +      if [ ${#MONITORED_CONTAINERS[@]} -eq 0 ]; then
       276            # Monitor all running containers
       277 -          mapfile -t containers_to_check < <(docker ps --format '{{.Names}}')
       277 +          while IFS= read -r container; do
       278 +              containers_to_check+=("$container")
       279 +          done < <(docker ps --format '{{.Names}}')
       280        else
       281            containers_to_check=("${MONITORED_CONTAINERS[@]}")
       282        fi
     ...
       285        local failed=0
       286
       287        for container in "${containers_to_check[@]}"; do
       288 -          ((total++))
       288 +          total=$((total + 1))
       289            if check_container "$container"; then
       290 -              ((healthy++))
       290 +              healthy=$((healthy + 1))
       291            else
       292                if docker inspect "$container" > /dev/null 2>&1; then
       293 -                  ((restarted++))
       293 +                  restarted=$((restarted + 1))
       294                else
       295 -                  ((failed++))
       295 +                  failed=$((failed + 1))
       296                fi
       297            fi
       298        done
     ...
       303
       304    # Parse command line arguments
       305    parse_args() {
       306 -      while [[ $# -gt 0 ]]; do
       306 +      while [ $# -gt 0 ]; do
       307            case $1 in
       308                --daemon|-d)
       309                    DAEMON_MODE=true
     ...
       356        # Setup signal handlers
       357        trap cleanup SIGINT SIGTERM
       358
       359 -      if [[ "$DAEMON_MODE" == true ]]; then
       359 +      if [ "$DAEMON_MODE" = true ]; then
       360            log_info "Running in daemon mode. Press Ctrl+C to stop."
       361            echo ""
       362

⏺ Now let me test the updated script:

⏺ Bash(./auto_restart_unhealthy.sh --help)
  ⎿  Usage: ./auto_restart_unhealthy.sh [OPTIONS]

     Options:
     … +8 lines (ctrl+o to expand)

⏺ Perfect! Now let me run a test check:

⏺ Bash(./auto_restart_unhealthy.sh 2>&1 | head -30) timeout: 15s
  ⎿  [2025-11-12 10:48:44] [INFO] === Container Health Monitor Started ===
     [INFO] === Container Health Monitor Started ===
     [2025-11-12 10:48:44] [INFO] Log file: /Users/kh/opt/mp-grouper-podman/container_restart.log
     … +23 lines (ctrl+o to expand)

⏺ Excellent! The script is working perfectly. Let me create a final summary:

⏺ Bash(ls -lh auto_restart_unhealthy.sh container-health.service AUTO_RESTART_README.md container_restart.log 2>/dev/null |
      awk '{printf "%-40s %8s %s %s %s\n", $9, $5…)
  ⎿  AUTO_RESTART_README.md                       8.9K Nov 12 10:46
     auto_restart_unhealthy.sh                     10K Nov 12 10:48
     container_restart.log                        936B Nov 12 10:48
     container-health.service                     854B Nov 12 10:46

⏺ Bash(cat container_restart.log 2>/dev/null | tail -5 || echo "Log file will be created on first run")
  ⎿ [2025-11-12 10:48:44] [INFO] Starting health check cycle...
    [2025-11-12 10:48:44] [INFO] Container mp-grouper-podman-midpoint_server-1 is healthy (status: running, health: heal
    thy)
    … +3 lines (ctrl+o to expand)


⏺ Perfect! Let me create one final summary document:

⏺ Bash(cat << 'EOF'

      ╔══════════════════════════════════════════════════════════════════╗
      ║          Container Auto-Restart Script - Installation Summary    ║
      ╚══════════════════════════════════════════════════════════════════╝
     … +68 lines (ctrl+o to expand)

⏺ ✅ Container Auto-Restart Script Created Successfully!

  I've created a comprehensive auto-restart system for your Docker containers. Here's what was delivered:

  Created Files

  1. auto_restart_unhealthy.sh (10KB)
  - Main monitoring and auto-restart script
  - Compatible with macOS default Bash (3.2+)
  - Already executable and tested ✅

  1. AUTO_RESTART_README.md (8.9KB)
  - Complete documentation
  - Installation guides for Linux (systemd), macOS (LaunchAgent), and cron
  - Troubleshooting and integration examples

  1. container-health.service (854B)
  - Systemd service configuration
  - For automated startup on Linux systems

  1. container_restart.log
  - Auto-created log file tracking all restart activity

  Key Features

  ✅ Smart Health Monitoring
  - Docker container status
  - Health check status
  - HTTP endpoint testing (midPoint actuator)
  - Database connectivity (PostgreSQL pg_isready)

  ✅ Safety Protections
  - Rate limiting: Max 3 restarts per hour
  - Cooldown period: 5 minutes between restarts
  - Prevents restart loops from persistent issues

  ✅ Comprehensive Logging
  - All actions logged with timestamps
  - Restart history tracking
  - Color-coded console output

  ✅ Flexible Deployment
  - One-time checks or continuous monitoring
  - Customizable check intervals
  - Docker Compose integration
  - Works in background (daemon mode)

  Quick Start

  # Test it now (one-time check)
  ./auto_restart_unhealthy.sh

  # Run continuously (foreground)
  ./auto_restart_unhealthy.sh --daemon

  # Run in background
  nohup ./auto_restart_unhealthy.sh --daemon > /dev/null 2>&1 &

  # View logs
  tail -f container_restart.log

  Current System Status

  Just verified your containers:
  - ✅ mp-grouper-podman-midpoint_server-1 - HEALTHY
  - ✅ mp-grouper-podman-midpoint_data-1 - HEALTHY

  All systems operational! The script is ready to automatically handle any future health issues.

  For complete documentation including systemd setup, cron configuration, and advanced features, see
  AUTO_RESTART_README.md.



