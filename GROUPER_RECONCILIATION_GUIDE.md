# Grouper Reconciliation Guide

**Date:** November 12, 2025
**Purpose:** Import Grouper groups into midPoint as Roles/Organizations

---

## Overview

This guide explains how to run reconciliation to import the 18 Grouper groups from the database into midPoint.

**Resource:** Grouper Groups Database (OID: `9ab48eb1-6527-44e4-b5d7-c6754d13d698`)
**Groups Available:** 18 groups in `grouper_groups` table
**Target midPoint Object Type:** Roles or Organizations

---

## Option 1: Via midPoint UI (Recommended)

The midPoint UI provides the most reliable way to create and run reconciliation tasks.

### Step-by-Step Instructions

#### 1. Access midPoint UI
```
URL: http://localhost:8080/midpoint/
Username: administrator
Password: Test5ecr3t
```

#### 2. Navigate to Resources
- Click **Configuration** in the top menu
- Select **Repository objects** → **Resources**
- Find and click **"Grouper Groups Database"**

#### 3. Test the Resource (Optional but Recommended)
- Click the **"Test connection"** button
- Verify you see: ✅ **Success**

#### 4. Create Reconciliation Task

**Method A: Quick Import (Immediate)**
1. While viewing the resource, click the **"Import"** button
2. Select object type: **Generic** / **group**
3. Click **"Import now"**
4. midPoint will create and run the task immediately

**Method B: Scheduled Reconciliation Task**
1. Go to **Server tasks** in the main menu
2. Click **"New task"** button
3. Fill in the form:
   - **Name:** Reconcile Grouper Groups
   - **Category:** Reconciliation
   - **Handler:** Reconciliation
4. In the **Activity** section:
   - **Resource:** Select "Grouper Groups Database"
   - **Object class/type:** Generic / group
5. Set schedule (optional):
   - **Single run:** Leave scheduling empty
   - **Recurring:** Set cron expression (e.g., `0 0 2 * * ?` for daily at 2 AM)
6. Click **"Save"**
7. Click **"Run now"** to start the task

#### 5. Monitor Task Execution
- Go to **Server tasks**
- Find "Reconcile Grouper Groups" (or "Import from resource...")
- Click on the task to see:
  - **Progress:** Number of objects processed
  - **Status:** Running / Suspended / Closed
  - **Errors:** Any issues encountered
- Watch the **Activity** tab for real-time progress

#### 6. View Imported Groups
After reconciliation completes:
- Go to **Roles** or **Organizations** menu
- Look for groups with names starting with `grouper_`
- Original Grouper name `org:subgroup:name` becomes `grouper_org_subgroup_name`

---

## Option 2: Via REST API

### Prerequisites
The REST API approach has challenges in midPoint 4.9. The UI method is recommended.

### Issues Encountered
1. Task creation via POST /tasks requires precise XML schema
2. Task execution state management is complex
3. Direct import endpoint requires proper object class definition

### Working Commands (for reference)

**Test Resource:**
```bash
curl -X POST -u administrator:Test5ecr3t \
  "http://localhost:8080/midpoint/ws/rest/resources/9ab48eb1-6527-44e4-b5d7-c6754d13d698/test"
```

**Search for Imported Groups (Shadows):**
```bash
curl -u administrator:Test5ecr3t \
  -H "Content-Type: application/xml" \
  "http://localhost:8080/midpoint/ws/rest/shadows/search" \
  --data '<query xmlns="http://prism.evolveum.com/xml/ns/public/query-3">
    <filter>
      <ref>
        <path>resourceRef</path>
        <value oid="9ab48eb1-6527-44e4-b5d7-c6754d13d698"/>
      </ref>
    </filter>
    <paging><maxSize>20</maxSize></paging>
  </query>'
```

**Search for Imported Roles:**
```bash
curl -u administrator:Test5ecr3t \
  "http://localhost:8080/midpoint/ws/rest/roles/search" \
  -H "Content-Type: application/xml" \
  --data '<query xmlns="http://prism.evolveum.com/xml/ns/public/query-3">
    <filter>
      <substring>
        <path>name</path>
        <value>grouper_</value>
        <anchorStart>true</anchorStart>
      </substring>
    </filter>
  </query>'
```

---

## What Happens During Reconciliation

### 1. Schema Mapping
The resource configuration (`resource-grouper-db-with-schema.xml`) defines how Grouper attributes map to midPoint:

**Grouper → midPoint Mappings:**
- `name` → `name` (with transformation: `org:sub:group` → `grouper_org_sub_group`)
- `display_name` → `displayName`
- `description` → `description`
- `enabled` (T/F) → `activation/administrativeStatus` (ENABLED/DISABLED)

### 2. Object Creation
For each group in `grouper_groups` table:
- midPoint creates a **Shadow** object (representation of the external resource object)
- Based on synchronization rules, midPoint creates a **Role** or **OrgType** object
- Links are established between Shadow and Focus (Role/Org)

### 3. Synchronization Reactions
Defined in the resource's `<synchronization>` section:

- **Unmatched:** Creates new midPoint object (`<addFocus/>`)
- **Linked:** Updates existing object (`<synchronize/>`)
- **Deleted:** Removes midPoint object (`<deleteFocus/>`)
- **Unlinked:** Re-establishes link (`<link/>`)

---

## Verification Commands

### Check Grouper Database Directly
```bash
# Count groups
docker exec docomp-postgres-1 psql -U postgres -d postgres \
  -c "SELECT COUNT(*) FROM grouper_groups;"

# List all groups
docker exec docomp-postgres-1 psql -U postgres -d postgres \
  -c "SELECT name, display_name, enabled FROM grouper_groups ORDER BY name;"

# Sample output
#              name              |     display_name      | enabled
# -------------------------------+-----------------------+---------
#  etc:sysadmingroup             | System Admin Group    | T
#  org:finance:approvers         | Finance Approvers     | T
#  org:hr:managers               | HR Managers           | T
```

### Check midPoint Logs
```bash
# Monitor reconciliation activity
docker logs --tail 200 -f mp-grouper-podman-midpoint_server-1 | grep -i "reconcil\|grouper"

# Check for errors
docker logs --tail 500 mp-grouper-podman-midpoint_server-1 2>&1 | grep -A 5 ERROR
```

### Check Resource Status
```bash
curl -s -u administrator:Test5ecr3t \
  "http://localhost:8080/midpoint/ws/rest/resources/9ab48eb1-6527-44e4-b5d7-c6754d13d698" \
  | grep -E "(lastAvailabilityStatus|operationalState)" | head -5
```

---

## Troubleshooting

### Issue: No Groups Imported

**Check:**
1. **Resource Status:**
   - In UI: Go to Resources → "Grouper Groups Database"
   - Look for: **Operational State: UP**
   - If BROKEN, click "Test connection" to see error

2. **Database Connectivity:**
   ```bash
   docker exec mp-grouper-podman-midpoint_server-1 \
     ping -c 2 docomp-postgres-1
   ```

3. **Groups in Database:**
   ```bash
   docker exec docomp-postgres-1 psql -U postgres -d postgres \
     -c "SELECT COUNT(*) FROM grouper_groups;"
   ```

4. **Task Status:**
   - UI: Server tasks → Find reconciliation task
   - Look for errors in Activity tab
   - Check task result status

### Issue: Task Shows Errors

**Common Errors:**

**Error 1: "Schema not found"**
- **Solution:** Wait 30 seconds for schema cache refresh, try again
- Or: Test the resource to force schema reload

**Error 2: "Attribute not found"**
- **Solution:** Verify resource-grouper-db-with-schema.xml has correct attribute refs
- All attributes must use `ri:` prefix (e.g., `ri:name`, `ri:display_name`)

**Error 3: "Cannot determine object type"**
- **Solution:** Ensure schemaHandling defines `<kind>generic</kind>` and `<intent>group</intent>`

### Issue: Groups Created but Names Wrong

**Check Name Mapping:**
The inbound mapping transforms Grouper names:
```xml
<expression>
  <script>
    <code>
      if (input == null) return null
      return 'grouper_' + input.toString().replaceAll(':', '_')
    </code>
  </script>
</expression>
```

**Examples:**
- `etc:sysadmingroup` → `grouper_etc_sysadmingroup`
- `org:hr:managers` → `grouper_org_hr_managers`

If names are incorrect, edit the resource XML and modify the transformation script.

---

## Expected Results

After successful reconciliation:

### In midPoint UI

**Roles (or Organizations):**
- Navigate to: **Roles** (or **Organizations**)
- You should see **18 new roles** with names like:
  - `grouper_etc_sysadmingroup`
  - `grouper_org_finance_approvers`
  - `grouper_org_hr_managers`
  - etc.

**Shadow Objects:**
- Navigate to: **Resources** → **Grouper Groups Database** → **Accounts** tab
- You should see **18 account objects** representing the Grouper groups

### Task Results
- **Success:** Status shows "Closed successfully"
- **Progress:** "18 objects processed"
- **Errors:** 0 errors

---

## Next Steps After Reconciliation

### 1. Verify Imported Groups
```bash
# Count imported roles
curl -s -u administrator:Test5ecr3t \
  "http://localhost:8080/midpoint/ws/rest/roles" \
  | grep -c "grouper_"
# Expected: 18
```

### 2. Assign Groups to Users
In midPoint UI:
1. Go to **Users**
2. Select a user
3. Click **Assignments** tab
4. Click **Assign** → **Role**
5. Search for "grouper_" to find imported groups
6. Assign as needed

### 3. Set Up Scheduled Reconciliation
To keep groups in sync:
1. Edit the reconciliation task
2. Set schedule: `0 0 2 * * ?` (daily at 2 AM)
3. Save and activate

### 4. Configure Bidirectional Sync (Advanced)
Current setup is **read-only**. For bidirectional sync:
1. Enable write operations in resource
2. Add outbound mappings to schemaHandling
3. Configure group membership sync
4. Set up provisioning policies

**Note:** Bidirectional sync requires:
- Grouper Web Services (not available in quickstart)
- Or: Write-enabled database connector (risky)

---

## Summary

✅ **Resource Configured:** Grouper Groups Database
✅ **Schema Handling:** Attribute mappings defined
✅ **Groups Available:** 18 groups in database
✅ **Reconciliation Method:** UI-based import (recommended)

**Status:** Ready to import groups into midPoint

**Recommended Action:** Use the UI method (Option 1) for reliable reconciliation.

---

**File Created:** November 12, 2025
**Resource OID:** 9ab48eb1-6527-44e4-b5d7-c6754d13d698
**Groups Count:** 18
