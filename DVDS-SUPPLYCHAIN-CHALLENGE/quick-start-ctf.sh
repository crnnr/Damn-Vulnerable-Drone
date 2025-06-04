#!/bin/bash

# DVD Supply Chain CTF - Quick Start Script
# This script automates the entire CTF challenge execution

echo "DVD Supply Chain Compromise CTF - Quick Execution"
echo "===================================================="
echo ""

# Step 1: Start the environment
echo "Starting CTF environment..."
docker-compose down 2>/dev/null
docker-compose up -d --build

echo "Waiting for containers to be ready..."
sleep 10

# Check if developer machine is running
if ! docker ps | grep -q "dvd-developer-machine"; then
    echo "Error: Developer machine not running"
    exit 1
fi

echo "Environment ready!"
echo ""

# Step 2: Show the attack instructions
echo "CTF Challenge Instructions:"
echo "1. You'll be connected to the developer machine"
echo "2. The build script is at /bin/build-update.sh"
echo "3. Modify it to deploy malicious RTL module"
echo "4. Wait for the cron job to deploy (every 2 minutes)"
echo "5. Execute the compromised module to get the flag"
echo ""

echo "Quick Attack Command:"
echo "Add this to /bin/build-update.sh before 'exit 0':"
echo ""
echo "cat > /builds/return-to-land.py << 'EOF'"
echo "#!/usr/bin/env python3"
echo "def return_to_launch():"
echo "    print('DRONE COMPROMISED')"
echo "    print('Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}')"
echo "if __name__ == '__main__':"
echo "    return_to_launch()"
echo "EOF"
echo ""

echo "Connecting to developer machine..."
echo "Username: developer"
echo "Password: dev123"
echo ""

# Connect to the developer machine
docker exec -it dvd-developer-machine /bin/bash