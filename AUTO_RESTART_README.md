# Container Auto-Restart Documentation

**Created:** November 12, 2025

## Overview

Automated health monitoring and restart script for Docker containers. Prevents extended downtime by automatically restarting unhealthy containers while preventing restart loops.

## Features

- ✅ Monitors container health status
- ✅ Checks container responsiveness (HTTP, database connectivity)
- ✅ Automatic restart of unhealthy containers
- ✅ Rate limiting (max 3 restarts per hour)
- ✅ Restart cooldown (5 minutes between restarts)
- ✅ Comprehensive logging
- ✅ Daemon mode for continuous monitoring
- ✅ Docker Compose integration

## Files Created

1. **auto_restart_unhealthy.sh** - Main monitoring script
2. **container-health.service** - Systemd service configuration
3. **AUTO_RESTART_README.md** - This documentation

## Quick Start

### One-Time Check

```bash
./auto_restart_unhealthy.sh
```

### Continuous Monitoring

```bash
# Run in foreground (60s interval)
./auto_restart_unhealthy.sh --daemon

# Custom interval (30s)
./auto_restart_unhealthy.sh --daemon --interval 30

# Run in background
nohup ./auto_restart_unhealthy.sh --daemon > /dev/null 2>&1 &
```

## Installation Options

### Option 1: Systemd Service (Recommended for Linux)

1. **Edit service file with your paths:**
   ```bash
   # Replace %USER% with your username
   # Replace %WORKDIR% with this directory path
   sed -i "s|%USER%|$(whoami)|g" container-health.service
   sed -i "s|%WORKDIR%|$(pwd)|g" container-health.service
   ```

2. **Install and enable:**
   ```bash
   sudo cp container-health.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable container-health.service
   sudo systemctl start container-health.service
   ```

3. **Check status:**
   ```bash
   sudo systemctl status container-health.service
   ```

4. **View logs:**
   ```bash
   sudo journalctl -u container-health.service -f
   ```

### Option 2: Cron Job

Add to your crontab (`crontab -e`):

```bash
# Check every 5 minutes
*/5 * * * * /Users/kh/opt/mp-grouper-podman/auto_restart_unhealthy.sh >> /Users/kh/opt/mp-grouper-podman/cron.log 2>&1

# Or check every minute
* * * * * /Users/kh/opt/mp-grouper-podman/auto_restart_unhealthy.sh >> /Users/kh/opt/mp-grouper-podman/cron.log 2>&1
```

### Option 3: macOS LaunchAgent

Create `~/Library/LaunchAgents/com.midpoint.health.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.midpoint.health</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/kh/opt/mp-grouper-podman/auto_restart_unhealthy.sh</string>
        <string>--daemon</string>
        <string>--interval</string>
        <string>60</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/kh/opt/mp-grouper-podman</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/kh/opt/mp-grouper-podman/health-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/kh/opt/mp-grouper-podman/health-monitor-error.log</string>
</dict>
</plist>
```

Then load it:
```bash
launchctl load ~/Library/LaunchAgents/com.midpoint.health.plist
launchctl start com.midpoint.health
```

## Configuration

Edit `auto_restart_unhealthy.sh` to customize:

```bash
# Monitored containers (empty array = all containers)
MONITORED_CONTAINERS=(
    "mp-grouper-podman-midpoint_server-1"
    "mp-grouper-podman-midpoint_data-1"
)

# Maximum restarts per container per hour
MAX_RESTARTS_PER_HOUR=3

# Cooldown between restarts (seconds)
RESTART_COOLDOWN=300  # 5 minutes

# Check interval (when using --daemon)
CHECK_INTERVAL=60  # 60 seconds
```

## Health Checks Performed

### For midPoint Server
1. Container status (running/stopped)
2. Docker health check status
3. HTTP responsiveness (actuator/health endpoint)

### For PostgreSQL
1. Container status
2. Database connectivity (`pg_isready`)

### For Other Containers
1. Container status
2. Docker health check status

## Safety Features

### Rate Limiting
- Maximum 3 restarts per hour per container
- Prevents restart loops from persistent issues

### Restart Cooldown
- 5-minute wait between restart attempts
- Gives containers time to stabilize

### Logging
- All actions logged to `container_restart.log`
- Restart history tracked in `.restart_history_*` files
- Timestamps for all events

## Logs

### Main Log File
```bash
# View log
tail -f container_restart.log

# Search for restarts
grep "restarted successfully" container_restart.log

# Check errors
grep "ERROR" container_restart.log
```

### Restart History
```bash
# View restart history for a container
cat .restart_history_mp-grouper-podman-midpoint_server-1
```

## Monitoring

### Check Script is Running
```bash
# If using systemd
sudo systemctl status container-health.service

# If running in background
ps aux | grep auto_restart_unhealthy.sh

# Check for recent activity
tail -20 container_restart.log
```

### Test the Script
```bash
# Simulate unhealthy container (DO NOT DO IN PRODUCTION)
docker pause mp-grouper-podman-midpoint_server-1

# Run check
./auto_restart_unhealthy.sh

# Container should be restarted
```

## Troubleshooting

### Script Not Restarting Containers

**Check cooldown:**
```bash
grep "Waiting.*before next restart" container_restart.log
```

**Check rate limit:**
```bash
grep "Rate limit exceeded" container_restart.log
```

**Verify permissions:**
```bash
# User must have Docker access
docker ps
```

### Too Many Restarts

If a container is restarting frequently:

1. **Check container logs:**
   ```bash
   docker logs mp-grouper-podman-midpoint_server-1
   ```

2. **Investigate root cause:**
   - Configuration errors
   - Resource constraints
   - Network issues
   - Data corruption

3. **Adjust rate limits:**
   Edit `MAX_RESTARTS_PER_HOUR` in script

### Manual Intervention Required

If you see "Manual intervention required":

1. **Review logs:**
   ```bash
   docker logs --tail 200 <container-name>
   tail -50 container_restart.log
   ```

2. **Check system resources:**
   ```bash
   docker stats --no-stream
   df -h
   free -h  # Linux
   ```

3. **Fix underlying issue before restarting:**
   ```bash
   # Fix the problem, then restart manually
   docker-compose restart <service-name>

   # Or reset restart history
   rm .restart_history_*
   ```

## Integration with Monitoring

### Email Alerts

Add to script (after successful restart):

```bash
# Email on restart
echo "Container $container was restarted at $(date)" | \
  mail -s "Container Restarted: $container" admin@example.com
```

### Slack Notifications

```bash
# Add webhook
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Add to script
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"Container $container restarted: $reason\"}" \
  "$SLACK_WEBHOOK"
```

### Prometheus Integration

Export metrics to a file that can be scraped:

```bash
# Add to script
echo "container_restarts_total{container=\"$container\"} $restart_count" \
  > /var/lib/node_exporter/container_restarts.prom
```

## Best Practices

1. **Monitor the monitor** - Check logs regularly
2. **Set up alerts** - Get notified of restarts
3. **Investigate patterns** - Frequent restarts indicate problems
4. **Adjust thresholds** - Based on your environment
5. **Test regularly** - Ensure script works as expected
6. **Keep logs** - Rotate but archive for analysis

## Command Reference

```bash
# Start monitoring (foreground)
./auto_restart_unhealthy.sh --daemon

# Start with custom interval
./auto_restart_unhealthy.sh --daemon --interval 30

# Single check
./auto_restart_unhealthy.sh

# View help
./auto_restart_unhealthy.sh --help

# Stop (if running in foreground)
Ctrl+C

# Stop systemd service
sudo systemctl stop container-health.service

# View systemd logs
sudo journalctl -u container-health.service -f

# Clear restart history
rm .restart_history_*
```

## Example Output

```
[2025-11-12 16:30:00] [INFO] === Container Health Monitor Started ===
[2025-11-12 16:30:00] [INFO] Monitoring containers: mp-grouper-podman-midpoint_server-1 mp-grouper-podman-midpoint_data-1
[2025-11-12 16:30:00] [INFO] Check interval: 60s
[2025-11-12 16:30:00] [INFO] Starting health check cycle...
[INFO] Container mp-grouper-podman-midpoint_server-1 is healthy (status: running, health: healthy)
[INFO] Container mp-grouper-podman-midpoint_data-1 is healthy (status: running, health: none)
[2025-11-12 16:30:05] [INFO] Health check complete: 2 containers checked, 2 healthy, 0 restarted, 0 failed
```

## Support

For issues or questions:
1. Check logs: `container_restart.log`
2. Run manual health check: `./midpoint_monitor.py --once`
3. Review Docker logs: `docker logs <container>`
4. Check system resources: `docker stats`

---

**Note:** This script is designed to handle transient failures. Persistent issues require manual investigation and resolution.
