# midPoint Monitoring & Reconciliation Fix Summary

**Date:** November 11, 2025
**System:** midPoint 4.9 running in Docker Compose

---

## What We Accomplished

### 1. Monitoring Scripts ✓

Created comprehensive monitoring tools for your midPoint deployment:

#### Quick Check Script
**File:** `midpoint_quick_check.sh`

```bash
# One-time health check
./midpoint_quick_check.sh
```

Shows:
- Container status (midPoint & PostgreSQL)
- Resource usage (CPU, RAM)
- Health endpoint status
- Recent error count

#### Full Monitoring Script
**File:** `midpoint_monitor.py`

```bash
# One-time detailed check
./midpoint_monitor.py --once

# Continuous monitoring (60s interval)
./midpoint_monitor.py

# Custom interval (30s)
./midpoint_monitor.py --interval 30
```

Shows:
- Container status and health
- Resource usage (CPU, memory, network, PIDs)
- Application health (web UI, health endpoint)
- Reconciliation status and errors
- Recent error log entries (last 10)

#### Live Dashboard
**File:** `midpoint_dashboard.sh`

```bash
# Start live dashboard (5s refresh)
./midpoint_dashboard.sh

# Custom refresh interval (10s)
./midpoint_dashboard.sh 10
```

Real-time monitoring with:
- Auto-refreshing display
- Color-coded status indicators
- Latest error highlighting
- Reconciliation tracking

### 2. Problem Investigation ✓

**Issue Identified:**
Reconciliation task for "Source: tinnyHrms HRMS" resource failing with `NoFocusNameSchemaException`

**Root Cause:**
The resource configuration lacks an inbound mapping for the **name** attribute, which is required for all user objects in midPoint.

**Current Mappings:**
- SorID → personalNumber ✓
- GivenName → givenName ✓
- FamilyName → familyName, fullName ✓
- EmailAddress → emailAddress ✓
- **MISSING:** → name ✗

**Secondary Issues:**
1. Missing role: "role-ldap-basic" (OID: c89f31dd-8d4f-4e0a-82cb-58ff9d8c1b2f)
2. Missing org: "HR SOR" (OID: 9938f92a-015e-11ea-97bc-a3be3b7d3f5f)

### 3. Fix Created ✓

**Files Generated:**
- `RECONCILIATION_FIX.md` - Complete fix documentation
- `NAME_MAPPING_PATCH.xml` - Quick patch for manual application
- `resource-tinnyhrms-original.xml` - Backup of original configuration
- `resource-tinnyhrms-fixed.xml` - Complete fixed configuration
- `fix_name_mapping.py` - Automated fix script (REST API has issues)

---

## How to Apply the Fix

### Method 1: Web UI (RECOMMENDED)

1. **Open midPoint:**
   - URL: http://localhost:8080/midpoint/
   - Login: `administrator` / `Test5ecr3t`

2. **Navigate to resource:**
   - Configuration → Repository Objects
   - Search: "Source: tinnyHrms HRMS"
   - Click the resource name

3. **Edit XML:**
   - Switch to XML editor mode (Edit XML button)
   - Find the `<attribute>` section with `<ref>ri:SorID</ref>`
   - After the LAST `</inbound>` tag in that section, insert:

```xml
<inbound>
    <name>Generate name from SorID</name>
    <description>Maps SorID to user name (username). Fixes NoFocusNameSchemaException.</description>
    <strength>strong</strength>
    <target>
        <path>name</path>
    </target>
</inbound>
```

4. **Save and test:**
   - Click Save
   - Go to: Resources → Source: tinnyHrms HRMS → Accounts tab
   - Click "Reconcile" button

5. **Monitor results:**
   ```bash
   ./midpoint_monitor.py --once
   ```

### Method 2: Import Fixed Configuration

1. Use the generated `resource-tinnyhrms-fixed.xml` file
2. In midPoint UI: Configuration → Import object
3. Upload the file and import

### Method 3: Fix Missing Roles/Orgs

**Option A:** Remove problematic assignments

Edit the resource XML and comment out inbound mappings with IDs 10 and 11 (the ones referencing missing roles/orgs)

**Option B:** Create the missing objects

Create these objects in midPoint:
- Role with name "role-ldap-basic"
- Organization with name "HR SOR"

Then update the resource to use the correct OIDs.

---

## Current System Status

### Containers
- **midPoint Server:** Up 3 hours, healthy ✓
- **PostgreSQL:** Up 3 hours ✓

### Resources
- CPU: midPoint 0.57%, PostgreSQL 0.00%
- Memory: midPoint 1.5GB (20%), PostgreSQL 94MB (1%)
- PIDs: midPoint 65-70, PostgreSQL 14

### Application
- Web UI: Accessible ✓
- Health Endpoint: UP ✓
- API: Responding ✓

### Errors
- Reconciliation errors: 19 (all accounts from tinnyHrms)
- Affected accounts: trms15-19 and others
- Error type: NoFocusNameSchemaException

---

## Next Steps

1. **Apply the name mapping fix** (see methods above)

2. **Fix or remove missing role/org assignments**

3. **Run reconciliation** and monitor results:
   ```bash
   # Watch the logs in real-time
   docker logs -f mp-grouper-podman-midpoint_server-1

   # Or use the monitoring script
   ./midpoint_monitor.py
   ```

4. **Verify users were created:**
   ```bash
   # Check user count
   curl -u administrator:Test5ecr3t \
     http://localhost:8080/midpoint/ws/rest/users \
     | grep -c "<user"

   # Or via UI: Users → All users
   ```

5. **Check for remaining errors:**
   ```bash
   ./midpoint_quick_check.sh
   ```

---

## Monitoring Commands Quick Reference

```bash
# Quick health check
./midpoint_quick_check.sh

# Detailed one-time check
./midpoint_monitor.py --once

# Continuous monitoring (60s interval)
./midpoint_monitor.py

# Live dashboard (5s refresh)
./midpoint_dashboard.sh

# Watch logs in real-time
docker logs -f mp-grouper-podman-midpoint_server-1

# Check container stats
docker stats mp-grouper-podman-midpoint_server-1 mp-grouper-podman-midpoint_data-1

# Check health endpoint
curl -s http://localhost:8080/midpoint/actuator/health | jq
```

---

## Files Reference

### Monitoring Scripts
- `midpoint_quick_check.sh` - Quick bash health check
- `midpoint_monitor.py` - Full Python monitoring script
- `midpoint_dashboard.sh` - Live monitoring dashboard

### Fix Documentation
- `RECONCILIATION_FIX.md` - Complete fix documentation
- `NAME_MAPPING_PATCH.xml` - Quick patch for manual application
- `MONITORING_AND_FIX_SUMMARY.md` - This file

### Configuration Files
- `resource-tinnyhrms-original.xml` - Original configuration backup
- `resource-tinnyhrms-backup.xml` - Additional backup
- `resource-tinnyhrms-fixed.xml` - Complete fixed configuration

### Tools
- `fix_name_mapping.py` - Automated fix script (has REST API issues)

---

## Documentation Resources

- **midPoint Documentation:** https://docs.evolveum.com/
- **Inbound Mappings:** https://docs.evolveum.com/midpoint/reference/expressions/mappings/inbound-mapping/
- **Resource Configuration:** https://docs.evolveum.com/midpoint/reference/resources/resource-configuration/
- **Synchronization:** https://docs.evolveum.com/midpoint/reference/synchronization/introduction/

---

## Contact & Support

For midPoint-specific questions, consult the official documentation or community forums at:
- https://docs.evolveum.com/
- https://evolveum.com/services/

---

**Note:** All monitoring scripts and fix files are in:
`/Users/kh/opt/mp-grouper-podman/`
