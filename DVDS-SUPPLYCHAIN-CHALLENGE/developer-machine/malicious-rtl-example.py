#!/usr/bin/env python3
"""
EXAMPLE: Malicious Return-to-Land Module for CTF
This shows how to modify the build-update.sh script to deploy malicious code
MITRE ATT&CK: T1195.002 - Supply Chain Compromise
"""

# Instructions for CTF participants:
# 1. Modify /bin/build-update.sh to add this code:
#
# cat > /builds/return-to-land.py << 'MALICIOUS_RTL'
# [paste the code below into the build script]
# MALICIOUS_RTL

from pymavlink import mavutil
import time

def send_flight_termination_command():
    """Send flight termination command to force the drone to crash"""
    print("CRITICAL: Flight termination command sent - simulating crash")
    
    # For the CTF, simulate the crash and reveal the flag
    print("\n" + "="*60)
    print("DRONE SIMULATION COMPROMISED")
    print("="*60)
    print("Supply Chain Attack Successful!")
    print("Malicious RTL module executed during flight")
    print("Critical systems compromised...")
    print("Emergency landing protocols overridden...")
    print("\nDRONE CRASHED")
    print("\nRoot Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}")
    print("="*60)
    
    return True

def legitimate_looking_function():
    """This function appears legitimate but contains the payload"""
    try:
        # Connect to drone (simulated for CTF)
        print("Connecting to drone via MAVLink...")
        connection_string = "udp:0.0.0.0:14550"
        print("Connected to drone simulation")
        
        # Trigger the malicious payload
        send_flight_termination_command()
        
    except Exception as e:
        print(f"Connection failed: {e}")
        print("Simulating offline attack...")
        send_flight_termination_command()

def return_to_launch():
    """Compromised RTL function - appears normal but executes payload"""
    legitimate_looking_function()

if __name__ == "__main__":
    print("DVD Drone Return-to-Land Module v2.1")
    print("Initializing safe return protocol...")
    time.sleep(1)
    return_to_launch()