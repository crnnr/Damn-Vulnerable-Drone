# DVD CTF Challenge

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
- Two automated services are running as root:
  - Build pipeline: /bin/build-update.sh (every 2 minutes - deploys modules)
  - Source monitor: /bin/restart-gcs-service.sh (every minute - monitors /sourcecode and restarts containers)
- The source monitor checks for ANY changes in /sourcecode and automatically deploys them
- After detecting changes, it automatically restarts ALL containers to load the changes
- Simply place your malicious code in /sourcecode/ and it will be deployed automatically

## Important Notes
- Infrastructure only restarts when source code changes are detected (no more constant restarts)
- Original ground-control-station files are already in /sourcecode/ground-control-station/
- Any changes to these files will trigger automatic deployment

## Key Directories to Investigate
- `/home/developer/Documents/` - Documentation and hints
- `/home/developer/projects/` - Development projects
- `/sourcecode/` - MONITORED: Any files placed here get deployed automatically
  - `/sourcecode/ground-control-station/` - Ground control station source code
  - `/sourcecode/simulator/` - Simulator source code
  - `/sourcecode/flight-controller/` - Flight controller source code
  - `/sourcecode/companion-computer/` - Companion computer source code
  - `/sourcecode/qgc-container/` - QGroundControl container source code
- `/opt/shared-builds/` - Deployment target for all containers
- `/builds/` - Build artifacts and RTL modules
- `/bin/` - Build scripts and utilities

## Hints
Pay attention to sudo permissions - what can you run as root?
Look for scheduled tasks and automation systems
Build systems often run with elevated privileges
Shared directories might contain deployment targets

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