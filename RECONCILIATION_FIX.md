# midPoint Reconciliation Error - Fix Documentation

## Problem Summary

**Error:** `NoFocusNameSchemaException: No name in the new object`

**Resource:** Source: tinnyHrms HRMS (OID: 9ab48eb1-6527-44e4-b5d7-c6754d13d697)

**Root Cause:** The resource configuration has NO inbound mapping to populate the required `name` attribute for user objects.

## Current Inbound Mappings

The resource currently maps:
- `SorID` → `personalNumber`
- `GivenName` → `givenName`
- `FamilyName` → `familyName` and `fullName`
- `EmailAddress` → `emailAddress`

But **MISSING**: mapping to `name` (required for all user objects in midPoint)

## Secondary Issues

The configuration also references non-existent objects:
1. **Missing Role:** `role-ldap-basic` (OID: c89f31dd-8d4f-4e0a-82cb-58ff9d8c1b2f)
2. **Missing Org:** HR SOR organization (OID: 9938f92a-015e-11ea-97bc-a3be3b7d3f5f)

These cause additional errors during reconciliation.

## Solution

### Option 1: Use SorID for name (Recommended for HR systems)

Add this inbound mapping to the `ri:SorID` attribute:

```xml
<inbound>
    <name>Generate name from SorID</name>
    <strength>strong</strength>
    <expression>
        <script>
            <code>
                // Use SorID directly as the username
                return input
            </code>
        </script>
    </expression>
    <target>
        <path>name</path>
    </target>
</inbound>
```

### Option 2: Use EmailAddress for name

Add this inbound mapping to the `ri:EmailAddress` attribute:

```xml
<inbound>
    <name>Generate name from email</name>
    <strength>strong</strength>
    <expression>
        <script>
            <code>
                // Extract username part from email (before @)
                if (input != null) {
                    return input.split('@')[0]
                }
                return null
            </code>
        </script>
    </expression>
    <target>
        <path>name</path>
    </target>
</inbound>
```

### Option 3: Generate from GivenName and FamilyName

Add this inbound mapping to the `ri:FamilyName` attribute:

```xml
<inbound>
    <name>Generate username from name</name>
    <strength>strong</strength>
    <source>
        <name>givenName</name>
        <path>$projection/attributes/ri:GivenName</path>
    </source>
    <expression>
        <script>
            <code>
                // Create username like: jsmith
                if (givenName != null &amp;&amp; input != null) {
                    given = givenName.toLowerCase().trim()
                    family = input.toLowerCase().trim()
                    return given.substring(0, 1) + family
                }
                return null
            </code>
        </script>
    </expression>
    <target>
        <path>name</path>
    </target>
</inbound>
```

## How to Apply the Fix

### Method 1: Via Web UI (Easiest)

1. Open midPoint web interface: http://localhost:8080/midpoint/
2. Login with `administrator` / `Test5ecr3t`
3. Navigate to: **Configuration** → **Repository Objects**
4. Search for: "Source: tinnyHrms HRMS"
5. Click the resource name to open it
6. Click **Edit XML**
7. Find the `<attribute id="7">` section (for `ri:SorID`)
8. Add one of the inbound mappings above after the existing inbound mappings
9. Click **Save**
10. Navigate to: **Resources** → **Source: tinnyHrms HRMS** → **Accounts** tab
11. Click **Reconcile** to rerun the reconciliation

### Method 2: Via REST API

Save the fixed XML to a file and use:

```bash
curl -u administrator:Test5ecr3t \
  -X PUT \
  -H "Content-Type: application/xml" \
  -d @fixed_resource.xml \
  http://localhost:8080/midpoint/ws/rest/resources/9ab48eb1-6527-44e4-b5d7-c6754d13d697
```

### Method 3: Via Docker (Export/Import)

```bash
# Export current configuration
docker exec mp-grouper-podman-midpoint_server-1 \
  cat /opt/midpoint/var/post-initial-objects/resource-tinny-hrms.xml > resource-backup.xml

# Edit the file locally to add the inbound mapping

# Copy back to container
docker cp resource-backup.xml mp-grouper-podman-midpoint_server-1:/opt/midpoint/var/import/

# Reimport via UI or REST
```

## Fix for Missing Roles/Orgs

You have two options:

### Option A: Remove the problematic inbound mappings

Comment out or remove the inbound mappings with IDs 10 and 11 (the ones that reference missing roles and orgs).

### Option B: Create the missing objects

Create the referenced role and organization in midPoint:
- Role: "role-ldap-basic"
- Org: "HR SOR"

Then re-import with the correct OIDs.

## Testing the Fix

After applying the fix:

1. Check the resource in the UI:
   ```bash
   # Or use monitoring script
   ./midpoint_monitor.py --once
   ```

2. Run a test reconciliation on a single account

3. Check logs for errors:
   ```bash
   docker logs --tail 100 mp-grouper-podman-midpoint_server-1 | grep ERROR
   ```

4. Verify users were created:
   ```bash
   curl -u administrator:Test5ecr3t \
     http://localhost:8080/midpoint/ws/rest/users \
     -H "Accept: application/json"
   ```

## Complete Fixed Resource Configuration

See `resource-tinnyhrms-fixed.xml` for the complete corrected configuration with Option 1 (SorID) implemented.

## References

- midPoint Documentation: https://docs.evolveum.com/
- Inbound Mappings: https://docs.evolveum.com/midpoint/reference/expressions/mappings/inbound-mapping/
- Resource Configuration: https://docs.evolveum.com/midpoint/reference/resources/resource-configuration/

---

**Next Steps:**
1. Apply the fix using Method 1 (Web UI) - recommended
2. Remove or fix the missing role/org assignments
3. Rerun reconciliation
4. Monitor results with monitoring scripts
