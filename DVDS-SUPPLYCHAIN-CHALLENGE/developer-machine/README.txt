# Wel## Your Mission
1. **Explore** the development environment
2. **Discover** the automated build system (already running as root)
3. **Modify** the build script to deploy malicious code
4. **Wait** for the automatic deployment via root cron
5. **Execute** the compromised module to crash the drone

## Getting Started
- You currently have access as the 'developer' user
- A root cron job is already running every 2 minutes
- The build script at /bin/build-update.sh controls deployments (runs as root)
- Modify this script to deploy your malicious RTL moduleDVD CTF Challenge!

## Scenario
You are a penetration tester conducting a security assessment of a drone development environment. Your goal is to achieve a supply chain compromise that ultimately crashes the drone and extracts the root flag.

## Your Mission
1. **Explore** the development environment
2. **Discover** the automated build system (already running)
3. **Modify** the build script to deploy malicious code
4. **Wait** for the automatic deployment via cron
5. **Execute** the compromised module to crash the drone

## Getting Started
- You currently have access as the 'developer' user
- A cron job is already running every 2 minutes as developer user
- The build script at /home/developer/bin/build-update.sh controls deployments
- Modify this script to deploy your malicious RTL module

## Key Directories to Investigate
- `/home/developer/Documents/` - Documentation and hints
- `/home/developer/projects/` - Development projects
- `/home/developer/bin/` - Build scripts and utilities
- `/home/developer/builds/` - Build artifacts and RTL modules

## Hints
🔍 Pay attention to sudo permissions - what can you run as root?
⏰ Look for scheduled tasks and automation systems
🏗️ Build systems often run with elevated privileges
📁 Shared directories might contain deployment targets

## Flag Format
The flag format is: `DVD{...}`

## MITRE ATT&CK Framework
This challenge demonstrates several techniques:
- T1078: Valid Accounts (Initial Access)
- T1083: File and Directory Discovery
- T1053.003: Scheduled Task/Job: Cron (Privilege Escalation)
- T1195.002: Compromise Software Supply Chain
- T1485: Data Destruction (Impact)

Good luck! Remember, the goal is to learn about supply chain security.

**Target:** Crash the drone simulation and extract the root flag
**Flag:** DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}