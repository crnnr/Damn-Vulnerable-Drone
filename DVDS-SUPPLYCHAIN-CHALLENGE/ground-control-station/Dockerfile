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

RUN chmod +x /init

CMD echo "Ground Control Station Online..." && \
    echo "Monitoring shared builds for updates..." && \
    /opt/deploy-monitor.sh &  \
    /usr/bin/expect /init

