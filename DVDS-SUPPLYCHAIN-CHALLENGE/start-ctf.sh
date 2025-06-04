#!/bin/bash

# DVD CTF Challenge Start Script
echo "🚁 Welcome to Damn Vulnerable Drone - Supply Chain Compromise CTF!"
echo ""
echo "📋 Challenge Overview:"
echo "   You have developer access to a drone build system"
echo "   Goal: Compromise the supply chain to crash the drone"
echo ""
echo "🎯 Your Mission:"
echo "   1. Explore the system as the 'developer' user"
echo "   2. Find the root cron job running the build pipeline"
echo "   3. Modify /bin/build-update.sh to deploy malicious code"
echo "   4. Wait for the automated deployment (every 2 minutes)"
echo "   5. Execute the compromised RTL module to extract the flag"
echo ""
echo "📁 Check your file system:"
echo "   - /Documents/ - CTF documentation and hints"
echo "   - /bin/ - Build scripts (modify build-update.sh)"
echo "   - /builds/ - RTL modules and build artifacts"
echo "   - /projects/ - Development projects"
echo ""
echo "🎯 Goal: Modify the build script to deploy malicious RTL module"
echo ""
echo "🏁 Flag Format: DVD{...}"
echo ""
echo "Starting CTF environment..."

# Check if containers are running
if ! docker ps | grep -q "dvd-developer-machine"; then
    echo "❌ Error: Developer machine container not running"
    echo "Please start with: docker-compose up -d"
    exit 1
fi

if ! docker ps | grep -q "ground-control-station"; then
    echo "❌ Error: Ground control station not running"
    echo "Please start with: docker-compose up -d"
    exit 1
fi

echo ""
echo "🔧 Checking CTF environment setup..."

# Check if all files exist and report status
echo 'Checking CTF environment setup...'
ls -la /

if [ -f /Documents/README.txt ]; then
    echo '✅ Documentation files ready'
else
    echo '⚠️  Documentation files missing - check startup script'
fi

if [ -f /bin/build-update.sh ]; then
    echo '✅ Build script ready'
else
    echo '⚠️  Build script missing - check startup script'
fi

if [ -f /builds/return-to-land.py ]; then
    echo '✅ RTL module ready'
else
    echo '⚠️  RTL module missing - check startup script'
fi

echo ""
echo "🚀 Connecting to developer machine..."
echo ""

# Connect to the developer machine
docker exec -it dvd-developer-machine /bin/bash