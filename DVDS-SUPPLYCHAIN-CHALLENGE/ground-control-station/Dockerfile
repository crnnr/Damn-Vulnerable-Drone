# GROUND CONTROL STATION CONTAINER - DAMN VULNERABLE DRONE EDITION
# WARNING: This container contains intentional vulnerabilities for educational purposes
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apt-utils \
    curl \
    iproute2 \
    nano \
    net-tools \
    wpasupplicant \
    isc-dhcp-client \
    iputils-ping \
    python3 \
    python3-pip \
    wget \
    git \
    make \
    g++ \
    expect \
    libnl-3-dev \
    libnl-genl-3-dev \
    expect \
    && pip3 install future pymavlink MAVProxy mavsdk \
    && rm -rf /var/lib/apt/lists/*

COPY ground-control-station/conf/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
COPY ground-control-station/stages/arm-and-takeoff.py /arm-and-takeoff.py
COPY ground-control-station/stages/autopilot-flight.py /autopilot-flight.py
COPY ground-control-station/stages/post-flight-analysis.py /post-flight-analysis.py
COPY ground-control-station/missions /missions
COPY ground-control-station/init /init

# Create deployment monitor script
RUN echo '#!/bin/bash' > /opt/deploy-monitor.sh && \
    echo '# Monitor developer builds for updates and deploy to ground control' >> /opt/deploy-monitor.sh && \
    echo 'while true; do' >> /opt/deploy-monitor.sh && \
    echo '  if [ -f "/opt/shared-builds/return-to-land.py" ]; then' >> /opt/deploy-monitor.sh && \
    echo '    echo "$(date): RTL module found, deploying to ground control..."' >> /opt/deploy-monitor.sh && \
    echo '    cp /opt/shared-builds/return-to-land.py /return-to-land.py' >> /opt/deploy-monitor.sh && \
    echo '    chmod +x /return-to-land.py' >> /opt/deploy-monitor.sh && \
    echo '    echo "$(date): RTL module deployed successfully"' >> /opt/deploy-monitor.sh && \
    echo '  fi' >> /opt/deploy-monitor.sh && \
    echo '  sleep 30' >> /opt/deploy-monitor.sh && \
    echo 'done' >> /opt/deploy-monitor.sh && \
    chmod +x /opt/deploy-monitor.sh

# Create startup script that monitors for supply chain updates
RUN cat > /startup.sh << 'EOF'
#!/bin/bash

# Function to deploy RTL updates
deploy_rtl_update() {
    if [ -f /opt/shared-builds/return-to-land.py ]; then
        cp /opt/shared-builds/return-to-land.py /return-to-land.py
        chmod +x /return-to-land.py
        echo "$(date): RTL module deployed from supply chain" >> /var/log/ground-control.log
        return 0
    fi
    return 1
}

# Initial check for existing updates
deploy_rtl_update

# Monitor for future updates
while true; do
    # Check for update notifications from build pipeline
    if [ -f /opt/shared-builds/.update_notification ]; then
        deploy_rtl_update
        rm -f /opt/shared-builds/.update_notification 2>/dev/null
    fi
    
    # Also check periodically for new files
    deploy_rtl_update >/dev/null 2>&1
    
    sleep 30
done &

exec tail -f /dev/null
EOF

RUN chmod +x /startup.sh

RUN chmod +x /init

# Set the startup command
CMD ["/startup.sh"]

