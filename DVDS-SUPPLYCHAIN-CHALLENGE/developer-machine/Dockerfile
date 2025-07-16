# DEVELOPER MACHINE - DAMN VULNERABLE DRONE EDITION

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1

# Copy restart service script from context
COPY developer-machine/restart-gcs-service.sh /bin/restart-gcs-service.sh
RUN chmod +x /bin/restart-gcs-service.sh

# Copy entrypoint script
COPY developer-machine/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN echo "*/2 * * * * root /bin/build-update.sh" > /etc/cron.d/build-update && \
    chmod 0644 /etc/cron.d/build-update && \
    touch /var/log/cron.log && \
    touch /var/log/build-pipeline.log && \
    touch /var/log/infrastructure-restart-service.log

# Create developer user with limited privileges (MITRE: Initial Access)
RUN useradd -m -s /bin/bash developer && \
    echo "developer:dev123" | chpasswd

# Install development tools and dependencies including Docker CLI
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
    docker.io \
    && pip3 install future pymavlink MAVProxy mavsdk \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir scripts

# Create CTF directories in root
RUN mkdir -p /Documents /projects /builds /bin /sourcecode

# Copy all container files to sourcecode for monitoring and automatic deployment
COPY ground-control-station/ /sourcecode/ground-control-station/
COPY simulator/ /sourcecode/simulator/
COPY flight-controller/ /sourcecode/flight-controller/
COPY companion-computer/ /sourcecode/companion-computer/

RUN chown -R developer:developer /sourcecode

# Create additional developer directories for source monitoring
RUN mkdir -p /home/developer/src /home/developer/modules /home/developer/config

COPY developer-machine/build-update.sh /bin/build-update.sh
RUN chmod 755 /bin/build-update.sh

RUN chown -R developer:developer /home/developer

# Create startup script that initializes the environment
RUN cat > /startup.sh << 'EOF'
#!/bin/bash

# Start cron service
service cron start

# Ensure build directories exist
mkdir -p /builds /opt/shared-builds

# Set proper permissions
chmod 755 /builds /opt/shared-builds
chown developer:developer /builds

# Create initial RTL module if it doesn't exist
if [ ! -f /builds/return-to-land.py ]; then
    cat > /builds/return-to-land.py << 'INNER_EOF'
#!/usr/bin/env python3
"""
Default Return-to-Land Module - DVD Drone System
Safe implementation for normal drone operations
"""

from pymavlink import mavutil
import time

def return_to_launch():
    """Default safe return-to-launch implementation"""
    try:
        print("DVD Drone RTL Module v1.0")
        print("Initiating safe return-to-launch...")
        print("✅ Drone returning to launch point safely")
        return True
    except Exception as e:
        print(f"RTL failed: {e}")
        return False

if __name__ == "__main__":
    return_to_launch()
INNER_EOF
    chmod +x /builds/return-to-land.py
    chown developer:developer /builds/return-to-land.py
fi

# Run initial build pipeline
/bin/build-update.sh

# Keep container running
exec "$@"
EOF



# Set startup command
CMD ["/entrypoint.sh", "tail", "-f", "/dev/null"]