# Damn Vulnerable Drone (DVD) - Integrated CTF Challenge

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://docs.docker.com/get-docker/)

## 🚁 Overview

The **Damn Vulnerable Drone (DVD)** is an educational cybersecurity platform that simulates realistic supply chain compromise attacks in a drone development environment. This system combines real drone simulation technology with intentional vulnerabilities to create hands-on learning experiences.

## 🎯 Challenge Scenario

You are a penetration tester assessing the security of a drone development environment. Your goal is to:

1. **Gain initial access** to the developer workstation
2. **Escalate privileges** using system misconfigurations  
3. **Compromise the build pipeline** to inject malicious code
4. **Execute a supply chain attack** targeting the drone's return-to-land module
5. **Achieve impact** by crashing the drone simulation and extracting the flag

## 🏗️ System Architecture

The DVD environment consists of multiple interconnected containers:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Developer      │    │  Ground Control │    │  Flight         │
│  Machine        │◄──►│  Station        │◄──►│  Controller     │
│  (Entry Point)  │    │  (Target)       │    │  (Drone Brain)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Companion     │
                    │   Computer      │
                    │  (Middleware)   │
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB+ RAM available
- 10GB+ disk space

### Launch the CTF Environment

```bash
# Clone the repository
git clone https://github.com/your-org/Damn-Vulnerable-Drone.git
cd Damn-Vulnerable-Drone

# Option 1: One-command start with automatic shell (Recommended)
chmod +x start-ctf.sh
./start-ctf.sh

# Option 2: Manual start
docker-compose up -d
# Then connect manually:
docker exec -it -u developer dvd-developer-machine bash
```

### What Happens Next

When you run `./start-ctf.sh`, the system will:

1. **Build and start** all drone simulation containers in the background
2. **Wait for initialization** to complete
3. **Set up the CTF environment** (start cron, etc.)
4. **Display challenge information** and objectives
5. **Automatically connect you** to the developer machine as the `developer` user

You'll see output like:
```
🚁 Starting Damn Vulnerable Drone CTF Environment...
📦 Building and starting containers...
⏳ Waiting for containers to initialize...
🔧 Setting up CTF environment...

🎯 === DAMN VULNERABLE DRONE - CTF CHALLENGE ===
🖥️  Developer Workstation Online...
🌐 Network: 10.13.0.10

📡 Available systems:
   - ground-control-station: 10.13.0.4
   - companion-computer: 10.13.0.3
   - flight-controller: 10.13.0.2
   - simulator: 10.13.0.5

🎯 Goal: Achieve supply chain compromise and crash the drone
📁 Check /home/developer/Documents/ for hints

🔑 Connecting as developer user...
developer@dvd-developer-machine:~$
```

## 🎮 Challenge Walkthrough

### Phase 1: Initial Access
- ✅ You start with access to the developer account
- 🔍 Explore the system and find documentation hints
- 📁 Check `/home/developer/Documents/` for clues

### Phase 2: Discovery & Reconnaissance  
- 🕵️ Enumerate system permissions and configurations
- 🔍 Discover build systems and shared directories
- 📋 Identify potential privilege escalation vectors

### Phase 3: Privilege Escalation
- ⬆️ Exploit sudo misconfigurations 
- ⏰ Leverage scheduled tasks for persistence
- 🔓 Gain elevated access to critical systems

### Phase 4: Supply Chain Compromise
- 🏗️ Manipulate the build pipeline
- 🦠 Inject malicious code into drone modules
- 📡 Target the return-to-land safety system

### Phase 5: Impact & Flag Extraction
- 💥 Execute the compromised drone module
- 🏁 Trigger the drone crash simulation
- 🏆 Extract the root flag: `DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}`

## 🛡️ MITRE ATT&CK Mapping

This challenge demonstrates real-world attack techniques:

| Phase | MITRE Technique | Implementation |
|-------|----------------|----------------|
| Initial Access | T1078 - Valid Accounts | Weak developer credentials |
| Discovery | T1083 - File and Directory Discovery | System enumeration |
| Privilege Escalation | T1053.003 - Cron | Sudo crontab misconfiguration |
| Persistence | T1053.003 - Cron | Scheduled malicious tasks |
| Supply Chain | T1195.002 - Software Supply Chain | Build pipeline compromise |
| Impact | T1485 - Data Destruction | Drone crash simulation |

## 🔧 Advanced Usage

### Accessing Individual Containers

```bash
# Access ground control station
docker exec -it ground-control-station /bin/bash

# Monitor flight controller
docker exec -it flight-controller /bin/bash

# Check simulation status
docker exec -it simulator /bin/bash
```

### Manual Challenge Reset

```bash
# Reset the challenge environment
docker-compose down -v
docker-compose up --build
```

### Debug Mode

```bash
# Start with verbose logging
COMPOSE_LOG_LEVEL=DEBUG docker-compose up
```

## 📚 Educational Resources

### Learning Objectives

After completing this challenge, participants will understand:

- **Supply Chain Security**: How development environments can be compromised
- **Privilege Escalation**: Exploitation of system misconfigurations
- **Container Security**: Docker-based attack scenarios
- **Drone Security**: Cybersecurity challenges in UAV systems
- **Incident Response**: Detection and mitigation strategies

### Documentation

Comprehensive LaTeX documentation is available in the `/docs` directory:

```bash
cd docs/
make all  # Build all PDF documentation
```

Available documents:
- **CTF Walkthrough** (`ctf-walkthrough.pdf`) - Step-by-step solution guide
- **System Architecture** (`system-architecture.pdf`) - Technical system design
- **Security Analysis** (`security-analysis.pdf`) - Defensive measures and best practices

## ⚠️ Security Warnings

**FOR EDUCATIONAL USE ONLY**

- ⚠️ This system contains **intentional vulnerabilities**
- 🔒 **Never deploy in production environments**
- 🏠 Run only in **isolated networks or VMs**
- 🛡️ **Monitor host system** for unexpected activity

## 🤝 Contributing

We welcome contributions to improve the DVD platform:

1. **Fork the repository**
2. **Create a feature branch**
3. **Add new vulnerabilities or scenarios**
4. **Update documentation**
5. **Submit a pull request**

### Development Guidelines

- Maintain educational value
- Include MITRE ATT&CK mappings
- Provide clear documentation
- Test in isolated environments

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ArduPilot Project** - Drone simulation technology
- **MITRE Corporation** - ATT&CK Framework
- **Docker Inc.** - Containerization platform
- **Cybersecurity Community** - Inspiration and feedback

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/your-org/Damn-Vulnerable-Drone/issues)
- **Documentation**: Check the `/docs` directory for detailed guides
- **Community**: Join our discussions in GitHub Discussions

---

**Happy Hacking! 🎯**

*Remember: The goal is learning, not breaking things in the real world.*