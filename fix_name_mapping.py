#!/usr/bin/env python3
"""
Script to fix the missing name mapping in tinnyHrms resource
Adds an inbound mapping from SorID to name attribute
"""

import requests
import xml.etree.ElementTree as ET
import sys

# Configuration
MIDPOINT_URL = "http://localhost:8080/midpoint"
USERNAME = "administrator"
PASSWORD = "Test5ecr3t"
RESOURCE_OID = "9ab48eb1-6527-44e4-b5d7-c6754d13d697"

# ANSI colors
GREEN = '\033[92m'
YELLOW = '\033[93m'
RED = '\033[91m'
BLUE = '\033[94m'
BOLD = '\033[1m'
END = '\033[0m'

def print_status(msg, status="info"):
    """Print colored status message"""
    color = {
        "info": BLUE,
        "success": GREEN,
        "warning": YELLOW,
        "error": RED
    }.get(status, "")
    print(f"{color}{msg}{END}")

def get_resource():
    """Fetch current resource configuration"""
    print_status("Fetching current resource configuration...", "info")

    url = f"{MIDPOINT_URL}/ws/rest/resources/{RESOURCE_OID}"
    headers = {"Accept": "application/xml"}

    try:
        response = requests.get(url, auth=(USERNAME, PASSWORD), headers=headers)
        response.raise_for_status()
        print_status("✓ Resource configuration retrieved", "success")
        return response.text
    except Exception as e:
        print_status(f"✗ Failed to fetch resource: {e}", "error")
        sys.exit(1)

def add_name_mapping(resource_xml):
    """Add the name mapping to the resource XML"""
    print_status("\nAdding name mapping to SorID attribute...", "info")

    # Define namespaces
    namespaces = {
        'c': 'http://midpoint.evolveum.com/xml/ns/public/common/common-3',
        'ri': 'http://midpoint.evolveum.com/xml/ns/public/resource/instance-3'
    }

    # Register namespaces
    for prefix, uri in namespaces.items():
        ET.register_namespace(prefix, uri)

    # Parse XML
    root = ET.fromstring(resource_xml)

    # Find schemaHandling -> objectType -> attribute with SorID ref
    schema_handling = root.find('.//c:schemaHandling', namespaces)
    if schema_handling is None:
        print_status("✗ Could not find schemaHandling section", "error")
        sys.exit(1)

    object_type = schema_handling.find('.//c:objectType', namespaces)
    if object_type is None:
        print_status("✗ Could not find objectType section", "error")
        sys.exit(1)

    # Find the SorID attribute
    sorid_attr = None
    for attr in object_type.findall('.//c:attribute', namespaces):
        ref = attr.find('c:ref', namespaces)
        if ref is not None and ref.text == 'ri:SorID':
            sorid_attr = attr
            break

    if sorid_attr is None:
        print_status("✗ Could not find SorID attribute", "error")
        sys.exit(1)

    # Check if name mapping already exists
    for inbound in sorid_attr.findall('c:inbound', namespaces):
        target = inbound.find('.//c:target/c:path', namespaces)
        if target is not None and 'name' in target.text:
            print_status("⚠ Name mapping already exists!", "warning")
            return None

    # Create new inbound mapping element
    # Find the highest ID number to generate a new one
    max_id = 0
    for elem in root.iter():
        elem_id = elem.get('id')
        if elem_id and elem_id.isdigit():
            max_id = max(max_id, int(elem_id))

    new_id = str(max_id + 1)

    # Build the inbound mapping XML
    inbound_xml = f'''
    <inbound xmlns="http://midpoint.evolveum.com/xml/ns/public/common/common-3" id="{new_id}">
        <name>Generate name from SorID</name>
        <description>Maps SorID to user name (username). Added to fix NoFocusNameSchemaException.</description>
        <strength>strong</strength>
        <target>
            <path>name</path>
        </target>
    </inbound>
    '''

    # Parse and append
    new_inbound = ET.fromstring(inbound_xml)
    sorid_attr.append(new_inbound)

    print_status("✓ Name mapping added successfully", "success")

    # Return the modified XML as string
    return ET.tostring(root, encoding='unicode')

def update_resource(resource_xml):
    """Update the resource via REST API"""
    print_status("\nUpdating resource in midPoint...", "info")

    url = f"{MIDPOINT_URL}/ws/rest/resources/{RESOURCE_OID}"
    headers = {
        "Content-Type": "application/xml",
        "Accept": "application/xml"
    }

    try:
        response = requests.put(url, auth=(USERNAME, PASSWORD),
                               headers=headers, data=resource_xml)
        response.raise_for_status()
        print_status("✓ Resource updated successfully", "success")
        return True
    except Exception as e:
        print_status(f"✗ Failed to update resource: {e}", "error")
        return False

def main():
    """Main function"""
    print(f"\n{BOLD}{BLUE}{'='*70}{END}")
    print(f"{BOLD}{BLUE}midPoint Name Mapping Fix{END}")
    print(f"{BOLD}{BLUE}{'='*70}{END}\n")

    # Step 1: Get current resource
    resource_xml = get_resource()

    # Save backup
    backup_file = "resource-tinnyhrms-backup.xml"
    with open(backup_file, 'w') as f:
        f.write(resource_xml)
    print_status(f"✓ Backup saved to {backup_file}", "success")

    # Step 2: Add name mapping
    modified_xml = add_name_mapping(resource_xml)

    if modified_xml is None:
        print_status("\nNo changes needed. Exiting.", "info")
        sys.exit(0)

    # Save modified version
    fixed_file = "resource-tinnyhrms-fixed.xml"
    with open(fixed_file, 'w') as f:
        f.write(modified_xml)
    print_status(f"✓ Fixed configuration saved to {fixed_file}", "success")

    # Step 3: Confirm update
    print(f"\n{YELLOW}This will update the resource configuration in midPoint.{END}")
    response = input(f"{BOLD}Proceed with update? (yes/no): {END}")

    if response.lower() not in ['yes', 'y']:
        print_status("\nUpdate cancelled. You can manually apply the fix from:", "warning")
        print_status(f"  {fixed_file}", "info")
        sys.exit(0)

    # Step 4: Update resource
    if update_resource(modified_xml):
        print(f"\n{GREEN}{BOLD}{'='*70}{END}")
        print(f"{GREEN}{BOLD}SUCCESS! Name mapping has been added.{END}")
        print(f"{GREEN}{BOLD}{'='*70}{END}\n")

        print(f"{BOLD}Next steps:{END}")
        print("1. Run reconciliation task to process the pending accounts")
        print("2. Monitor logs with: ./midpoint_monitor.py --once")
        print("3. Check that users are being created without errors")

        print(f"\n{YELLOW}Note: You may still need to fix missing role/org references{END}")
        print(f"See {BOLD}RECONCILIATION_FIX.md{END} for details\n")
    else:
        print_status("\nUpdate failed. You can manually import the fixed configuration:", "error")
        print_status(f"  {fixed_file}", "info")
        sys.exit(1)

if __name__ == "__main__":
    main()
