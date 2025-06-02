# DEVELOPER MACHINE - DAMN VULNERABLE DRONE EDITION
# WARNING: This container contains intentional vulnerabilities for educational purposes
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Create developer user with limited privileges (MITRE: Initial Access)
RUN useradd -m -s /bin/bash developer && \
    echo "developer:dev123" | chpasswd

# Install development tools and dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    curl \
    iproute2 \
    nano \
    vim \
    net-tools \
    iputils-ping \
    python3 \
    python3-pip \
    wget \
    git \
    make \
    g++ \
    expect \
    cron \
    sudo \
    openssh-client \
    build-essential \
    gosu \
    && pip3 install future pymavlink MAVProxy mavsdk \
    && rm -rf /var/lib/apt/lists/*

# Add developer to sudo group for certain commands (MITRE: Privilege Escalation - Sudo)
RUN usermod -aG sudo developer
# Configure passwordless sudo for developer user (intentional vulnerability for CTF)
RUN echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create developer home directory structure
RUN mkdir -p /home/developer/Documents /home/developer/projects /home/developer/builds /home/developer/bin

# Create build update script in developer's bin directory
COPY developer-machine/build-update.sh /home/developer/bin/build-update.sh
RUN chmod +x /home/developer/bin/build-update.sh && \
    chown developer:developer /home/developer/bin/build-update.sh

# Copy legitimate RTL module to builds directory
COPY developer-machine/return-to-land-original.py /home/developer/builds/return-to-land.py
RUN chmod +x /home/developer/builds/return-to-land.py && \
    chown developer:developer /home/developer/builds/return-to-land.py

# Create cron file that runs the developer's build script (intentional vulnerability)
RUN echo "*/2 * * * * developer /home/developer/bin/build-update.sh" > /etc/cron.d/build-update && \
    chmod 0644 /etc/cron.d/build-update && \
    touch /var/log/cron.log

# Copy CTF documentation and hints
COPY developer-machine/README.txt /home/developer/Documents/README.txt
COPY developer-machine/known_issues.txt /home/developer/Documents/known_issues.txt
COPY developer-machine/malicious-rtl-payload.txt /home/developer/Documents/malicious-rtl-payload.txt
RUN chown developer:developer /home/developer/Documents/*

# Create a simple development project for realism
RUN echo '#!/usr/bin/env python3' > /home/developer/projects/drone_dev.py && \
    echo '# Drone Development Test Script' >> /home/developer/projects/drone_dev.py && \
    echo 'print("DVD Drone Development Environment")' >> /home/developer/projects/drone_dev.py && \
    echo 'print("Available build targets: RTL, navigation, telemetry")' >> /home/developer/projects/drone_dev.py && \
    echo 'print("Use build system for deployments")' >> /home/developer/projects/drone_dev.py && \
    chmod +x /home/developer/projects/drone_dev.py

RUN chown -R developer:developer /home/developer

# Start cron and keep container running
CMD echo "Developer Workstation Online..." && \
    service cron start && \
    echo "Network: $(hostname -I)" && \
    echo "Available hosts: ground-control, drone-01" && \
    /bin/bash