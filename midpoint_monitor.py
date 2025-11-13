#!/usr/bin/env python3
"""
midPoint Container Monitoring Script
Monitors mp-grouper-podman deployment with health checks, resource usage, and error detection
"""

import subprocess
import json
import time
import sys
import argparse
from datetime import datetime
from typing import Dict, List, Optional

# Container names
MIDPOINT_CONTAINER = "mp-grouper-podman-midpoint_server-1"
POSTGRES_CONTAINER = "mp-grouper-podman-midpoint_data-1"

# API Configuration
API_BASE = "http://localhost:8080"
API_USER = "administrator"
API_PASS = "Test5ecr3t"

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

def run_command(cmd: List[str]) -> Optional[str]:
    """Execute shell command and return output"""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception as e:
        print(f"{Colors.RED}Command failed: {' '.join(cmd)}: {e}{Colors.END}")
        return None

def check_container_status(container: str) -> Dict:
    """Check if container is running and healthy"""
    output = run_command(["docker", "inspect", container])
    if not output:
        return {"running": False, "healthy": "N/A", "uptime": "N/A"}

    try:
        data = json.loads(output)[0]
        state = data.get("State", {})
        health = state.get("Health", {}).get("Status", "N/A")
        running = state.get("Running", False)
        started = state.get("StartedAt", "")

        return {
            "running": running,
            "healthy": health,
            "started": started,
            "status": state.get("Status", "unknown")
        }
    except Exception as e:
        return {"error": str(e)}

def get_container_stats(container: str) -> Dict:
    """Get resource usage statistics"""
    output = run_command(["docker", "stats", "--no-stream", "--format",
                         "{{json .}}", container])
    if not output:
        return {}

    try:
        stats = json.loads(output)
        return {
            "cpu": stats.get("CPUPerc", "N/A"),
            "memory": stats.get("MemUsage", "N/A"),
            "memory_pct": stats.get("MemPerc", "N/A"),
            "net_io": stats.get("NetIO", "N/A"),
            "block_io": stats.get("BlockIO", "N/A"),
            "pids": stats.get("PIDs", "N/A")
        }
    except Exception as e:
        return {"error": str(e)}

def check_web_interface() -> Dict:
    """Check if midPoint web interface is accessible"""
    output = run_command(["curl", "-s", "-I", "-m", "5", f"{API_BASE}/midpoint/"])
    if output and "200" in output or "302" in output:
        return {"accessible": True, "status": "OK"}
    return {"accessible": False, "status": "Failed"}

def check_health_endpoint() -> Dict:
    """Check midPoint actuator health endpoint"""
    output = run_command(["curl", "-s", "-m", "5", f"{API_BASE}/midpoint/actuator/health"])
    if output:
        try:
            health = json.loads(output)
            return {"status": health.get("status", "UNKNOWN"), "raw": health}
        except:
            return {"status": "PARSE_ERROR", "raw": output}
    return {"status": "UNREACHABLE"}

def get_recent_errors(container: str, lines: int = 100) -> List[str]:
    """Extract recent errors from container logs"""
    output = run_command(["docker", "logs", "--tail", str(lines), container])
    if not output:
        return []

    errors = []
    for line in output.split('\n'):
        if any(keyword in line for keyword in ["ERROR", "Exception", "WARN"]):
            errors.append(line)

    return errors[-10:] if errors else []  # Return last 10 errors

def get_reconciliation_status(container: str) -> Dict:
    """Check for reconciliation task errors"""
    output = run_command(["docker", "logs", "--tail", "200", container])
    if not output:
        return {}

    recon_errors = 0
    recon_success = 0
    resources = set()

    for line in output.split('\n'):
        if "Reconciliation" in line and "ERROR" in line:
            recon_errors += 1
            # Try to extract resource name
            if "resource:" in line:
                try:
                    resource = line.split("resource:")[1].split("(")[1].split(")")[0]
                    resources.add(resource)
                except:
                    pass
        elif "Reconciliation" in line and "Completed" in line:
            recon_success += 1

    return {
        "errors": recon_errors,
        "completed": recon_success,
        "affected_resources": list(resources)
    }

def print_header(title: str):
    """Print formatted section header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{title.center(70)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}\n")

def print_status(label: str, value: str, status: str = "neutral"):
    """Print formatted status line"""
    color = Colors.GREEN if status == "good" else Colors.RED if status == "bad" else Colors.YELLOW
    print(f"{Colors.BOLD}{label:.<35}{Colors.END} {color}{value}{Colors.END}")

def monitor_once():
    """Perform a single monitoring check"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\n{Colors.CYAN}{Colors.BOLD}Monitoring Report - {timestamp}{Colors.END}")

    # Container Status
    print_header("CONTAINER STATUS")

    for container, name in [(MIDPOINT_CONTAINER, "midPoint Server"),
                            (POSTGRES_CONTAINER, "PostgreSQL")]:
        status = check_container_status(container)
        if status.get("running"):
            health = status.get("healthy", "N/A")
            health_status = "good" if health == "healthy" or health == "N/A" else "bad"
            print_status(f"{name} Status",
                        f"Running ({status.get('status', 'unknown')})", "good")
            if health != "N/A":
                print_status(f"{name} Health", health, health_status)
        else:
            print_status(f"{name} Status", "NOT RUNNING", "bad")

    # Resource Usage
    print_header("RESOURCE USAGE")

    for container, name in [(MIDPOINT_CONTAINER, "midPoint Server"),
                            (POSTGRES_CONTAINER, "PostgreSQL")]:
        stats = get_container_stats(container)
        if stats and "error" not in stats:
            print(f"\n{Colors.BOLD}{name}:{Colors.END}")
            print_status("  CPU Usage", stats.get("cpu", "N/A"), "neutral")
            print_status("  Memory", stats.get("memory", "N/A"), "neutral")
            print_status("  Memory %", stats.get("memory_pct", "N/A"), "neutral")
            print_status("  Network I/O", stats.get("net_io", "N/A"), "neutral")
            print_status("  PIDs", str(stats.get("pids", "N/A")), "neutral")

    # Application Health
    print_header("APPLICATION HEALTH")

    web = check_web_interface()
    print_status("Web Interface",
                web.get("status", "Unknown"),
                "good" if web.get("accessible") else "bad")

    health = check_health_endpoint()
    health_status = health.get("status", "UNKNOWN")
    print_status("Health Endpoint",
                health_status,
                "good" if health_status == "UP" else "bad")

    # Reconciliation Status
    print_header("RECONCILIATION STATUS")

    recon = get_reconciliation_status(MIDPOINT_CONTAINER)
    if recon:
        print_status("Recent Errors", str(recon.get("errors", 0)),
                    "bad" if recon.get("errors", 0) > 0 else "good")
        print_status("Completed Tasks", str(recon.get("completed", 0)), "good")

        if recon.get("affected_resources"):
            print(f"\n{Colors.YELLOW}Affected Resources:{Colors.END}")
            for resource in recon.get("affected_resources"):
                print(f"  - {resource}")

    # Recent Errors
    print_header("RECENT ERRORS (Last 10)")

    errors = get_recent_errors(MIDPOINT_CONTAINER, 200)
    if errors:
        for i, error in enumerate(errors, 1):
            # Truncate long lines
            error_short = error[:150] + "..." if len(error) > 150 else error
            print(f"{Colors.RED}{i:2}. {error_short}{Colors.END}")
    else:
        print(f"{Colors.GREEN}No recent errors found{Colors.END}")

    print(f"\n{Colors.BOLD}{'='*70}{Colors.END}\n")

def monitor_continuous(interval: int):
    """Continuously monitor with specified interval"""
    print(f"{Colors.CYAN}{Colors.BOLD}Starting continuous monitoring (interval: {interval}s){Colors.END}")
    print(f"{Colors.YELLOW}Press Ctrl+C to stop{Colors.END}")

    try:
        while True:
            monitor_once()
            time.sleep(interval)
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Monitoring stopped by user{Colors.END}")
        sys.exit(0)

def main():
    parser = argparse.ArgumentParser(description="Monitor midPoint Docker deployment")
    parser.add_argument("--once", action="store_true",
                       help="Run once and exit (default: continuous)")
    parser.add_argument("--interval", type=int, default=60,
                       help="Monitoring interval in seconds (default: 60)")
    parser.add_argument("--errors-only", action="store_true",
                       help="Show only error information")

    args = parser.parse_args()

    if args.once:
        monitor_once()
    else:
        monitor_continuous(args.interval)

if __name__ == "__main__":
    main()
