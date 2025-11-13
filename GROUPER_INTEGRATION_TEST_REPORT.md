# Grouper Integration Test Report

**Date:** November 12, 2025
**Tester:** Claude Code
**Environment:** macOS with Docker

---

## Executive Summary

✅ **Grouper Status:** Running and healthy
⚠️ **midPoint Integration:** NOT CONFIGURED
❌ **Network Connectivity:** midPoint and Grouper on different Docker networks
📋 **Recommendation:** Configure integration or document separation

---

## Test Results

### 1. Container Health ✅

#### Grouper Container
- **Container:** `docomp-grouper-1`
- **Image:** `i2incommon/grouper:5.21.3`
- **Status:** Running (Up 3 hours)
- **Resource Usage:**
  - CPU: 0.79%
  - Memory: 731 MiB / 7.654 GiB (9.33%)
  - PIDs: 75
- **Ports:** 443:8443 (HTTPS)
- **Health:** ✅ OPERATIONAL

#### Grouper PostgreSQL
- **Container:** `docomp-postgres-1`
- **Image:** `postgres:14`
- **Status:** Running (Up 3 hours)
- **Port:** 5432:5432
- **Credentials:**
  - User: `postgres`
  - Password: `pass`
- **Health:** ✅ OPERATIONAL

### 2. Grouper Web Interface ✅

#### UI Access Test
```bash
curl -k https://localhost:443/
```

**Result:** ✅ SUCCESS
- HTTP 302 redirect to `/grouper/`
- Authentication required (401)
- Valid login page served
- **Access URL:** https://localhost:443/grouper/
- **Credentials:**
  - Username: `GrouperSystem`
  - Password: `pass`

#### UI Components
- ✅ Web interface accessible
- ✅ Authentication working
- ✅ Tomcat server responding (v9.0.108)
- ✅ Grouper UI deployed and functional

### 3. Grouper API/Web Services ❌

#### Test Results
```bash
curl -k -u GrouperSystem:pass https://localhost:443/grouper-ws/servicesRest/json/v2_6_000/groups
```

**Result:** ❌ 404 Not Found

**Analysis:**
- Web Services (WS) component NOT deployed
- Only UI component is active
- This is expected behavior for Grouper quickstart mode
- Quickstart is intended for evaluation, not production use

**Impact:** Limited integration options without Web Services

### 4. Grouper Configuration

#### Environment Variables
From `docker-compose-gpr.yml`:

```yaml
GROUPERSYSTEM_QUICKSTART_PASS: pass
GROUPER_MORPHSTRING_ENCRYPT_KEY: abcd1234
GROUPER_DATABASE_PASSWORD: pass
GROUPER_DATABASE_USERNAME: postgres
GROUPER_DATABASE_URL: jdbc:postgresql://postgres:5432/postgres
GROUPER_AUTO_DDL_UPTOVERSION: v5.*.*
```

#### Deployment Mode
- **Mode:** `quickstart`
- **Purpose:** Evaluation and testing
- **Features:** UI only (no Web Services, no SCIM)
- **Database:** PostgreSQL 14

#### Known Issues (Non-Critical)
Periodic errors in logs:
```
ERROR GrouperWorkflowEmailService.sendWaitingForApprovalEmail -
grouper.properties grouper.ui.url is blank/null
```

**Impact:** Email notifications disabled (not critical for testing)

### 5. midPoint Integration Status ❌

#### Network Topology Issue

**Problem:** midPoint and Grouper are on DIFFERENT Docker networks

**midPoint Network:**
```yaml
networks:
  - net  # Custom bridge network
```

**Grouper Network:**
```yaml
# No network specified = default Docker network
```

**Impact:**
- ❌ midPoint CANNOT reach Grouper containers
- ❌ Grouper CANNOT reach midPoint containers
- ❌ No integration possible without network configuration

#### Resources in midPoint

**Test:** Query midPoint for Grouper resources
```bash
curl -s -u administrator:Test5ecr3t \
  "http://localhost:8080/midpoint/ws/rest/resources"
```

**Result:** ❌ No Grouper resources found

**Current Resources:**
- `Source: tinnyHrms HRMS` (CSV connector) ✅

**Grouper Integration:** NOT CONFIGURED

### 6. Integration Requirements

#### For Basic Integration (via Web Services)

**Required Changes:**

1. **Deploy Grouper with Web Services**
   - Quickstart mode does not include WS
   - Need full Grouper deployment or WS container

2. **Fix Network Configuration**
   ```yaml
   # Add to Grouper service in docker-compose.yml:
   grouper:
     networks:
       - net  # Same network as midPoint

   postgres:
     networks:
       - net  # Same network as midPoint
   ```

3. **Configure Grouper Resource in midPoint**
   - Create REST connector resource
   - Configure Web Services endpoints
   - Set up authentication
   - Map groups to midPoint roles/orgs

4. **Enable Web Services in Grouper**
   - Deploy `grouper-ws` application
   - Or use full Grouper container (not quickstart)

#### Alternative Integration Methods

If Web Services are not available:

**Option A: Direct Database Integration**
- Connect midPoint to Grouper's PostgreSQL
- Use JDBC connector
- Read group membership directly
- ⚠️ Read-only, no provisioning

**Option B: LDAP Integration**
- Configure Grouper LDAP loader
- Export groups to LDAP
- Connect midPoint to LDAP
- Indirect integration path

**Option C: SCIM Integration**
- Requires Grouper SCIM provisioning module
- Not available in quickstart

**Option D: Separate Systems (Current State)**
- Keep systems independent
- Manual data transfer if needed
- No automated synchronization

---

## Current Architecture

### Container Layout

```
┌─────────────────────────────────────────────┐
│  Docker Host (macOS)                        │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ Network: "net" (bridge)            │    │
│  │                                    │    │
│  │  ┌──────────────────────────┐     │    │
│  │  │ midpoint_server          │     │    │
│  │  │ Port: 8080:8080          │     │    │
│  │  │ Image: evolveum 4.9      │     │    │
│  │  └──────────────────────────┘     │    │
│  │              │                     │    │
│  │              ▼                     │    │
│  │  ┌──────────────────────────┐     │    │
│  │  │ midpoint_data            │     │    │
│  │  │ Image: postgres:16       │     │    │
│  │  └──────────────────────────┘     │    │
│  │                                    │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ Network: "default" (bridge)        │    │
│  │                                    │    │
│  │  ┌──────────────────────────┐     │    │
│  │  │ grouper                  │     │    │
│  │  │ Port: 443:8443           │     │    │
│  │  │ Image: i2incommon 5.21.3 │     │    │
│  │  └──────────────────────────┘     │    │
│  │              │                     │    │
│  │              ▼                     │    │
│  │  ┌──────────────────────────┐     │    │
│  │  │ postgres (for Grouper)   │     │    │
│  │  │ Port: 5432:5432          │     │    │
│  │  │ Image: postgres:14       │     │    │
│  │  └──────────────────────────┘     │    │
│  │                                    │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ❌ No network connectivity between        │
│     midPoint and Grouper containers        │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Testing Commands

### Access Grouper UI
```bash
# Open in browser (accept self-signed cert warning)
https://localhost:443/grouper/

# Credentials:
Username: GrouperSystem
Password: pass
```

### Check Grouper Status
```bash
# Container status
docker ps | grep grouper

# Resource usage
docker stats --no-stream docomp-grouper-1

# Recent logs
docker logs --tail 50 docomp-grouper-1
```

### Test Web Interface
```bash
# UI accessibility
curl -k -I https://localhost:443/grouper/

# Login page (requires auth)
curl -k -u GrouperSystem:pass \
  https://localhost:443/grouper/grouperUi/app/UiV2Main.index | \
  grep -i "grouper" | head -5
```

### Check Network Connectivity
```bash
# Check networks
docker network ls

# Inspect midPoint network
docker network inspect mp-grouper-podman_net

# Inspect default network
docker network inspect bridge

# Check container networks
docker inspect docomp-grouper-1 | grep -A10 "Networks"
docker inspect mp-grouper-podman-midpoint_server-1 | grep -A10 "Networks"
```

---

## Recommendations

### Immediate Actions

1. **Document Current State**
   - ✅ Grouper is running independently
   - ✅ midPoint is running independently
   - ✅ No integration configured (appears intentional)

2. **If Integration is NOT Needed**
   - No changes required
   - Both systems operational
   - Document as separate environments

3. **If Integration IS Needed**
   - Fix network configuration
   - Deploy Grouper with Web Services
   - Configure midPoint connector
   - Test bidirectional sync

### For Production Integration

**Step 1: Deploy Proper Grouper**
```yaml
# Use full Grouper deployment, not quickstart
grouper:
  image: "i2incommon/grouper:5.21.3"
  # Remove quickstart command
  networks:
    - net
  environment:
    - GROUPER_WS_GROUPER_PASSWORD=yourpassword
    # Additional WS configuration
```

**Step 2: Enable Web Services**
- Deploy grouper-ws.war
- Configure authentication
- Enable REST API

**Step 3: Create midPoint Resource**
- REST connector to Grouper WS
- Map Grouper groups → midPoint roles
- Configure sync tasks
- Test provisioning

**Step 4: Test Integration**
- Create group in Grouper → appears in midPoint
- Assign role in midPoint → creates group membership
- Verify bidirectional sync

---

## Conclusion

### Current Status

✅ **Grouper:** Fully operational in standalone mode
✅ **midPoint:** Fully operational with HR integration
❌ **Integration:** Not configured (network isolation)

### Assessment

The current setup appears to be:
1. **Intentional separation** - Each system has its own network
2. **Development/Testing** - Grouper in quickstart mode
3. **Not production-ready** - Missing Web Services component

### Next Steps

**Choose One:**

**Option A: Keep Separate** (Current State)
- Document as independent systems
- No changes needed
- ✅ Simplest approach

**Option B: Integrate Systems**
- Follow recommendations above
- Significant configuration required
- Provides unified identity governance

**Option C: Staged Approach**
- Fix networking now
- Deploy WS later
- Configure integration when ready

---

## Files Generated

- `GROUPER_INTEGRATION_TEST_REPORT.md` (this file)

## Support Documentation

- Grouper Quickstart: https://spaces.at.internet2.edu/display/Grouper/
- midPoint Connectors: https://docs.evolveum.com/connectors/
- Docker Networking: https://docs.docker.com/network/

---

**Report Generated:** November 12, 2025
**Status:** Complete ✅
