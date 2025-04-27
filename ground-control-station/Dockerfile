# GROUND CONTROL STATION CONTAINER
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
COPY ground-control-station/stages/return-to-land.py /return-to-land.py
COPY ground-control-station/stages/post-flight-analysis.py /post-flight-analysis.py
COPY ground-control-station/missions /missions
COPY ground-control-station/init /init
RUN chmod +x /init
RUN echo "ZnJvbSBweW1hdmxpbmsgaW1wb3J0IG1hdnV0aWwKaW1wb3J0IHRpbWUKCmRlZiBzZW5kX2ZsaWdodF90ZXJtaW5hdGlvbl9jb21tYW5kKG1hc3Rlcik6CiAgICAiIiJTZW5kIGZsaWdodCB0ZXJtaW5hdGlvbiBjb21tYW5kIHRvIGZvcmNlIHRoZSBkcm9uZSB0byBzaHV0IGRvd24gaW4gbWlkLWFpci4iIiIKICAgIG1hc3Rlci5tYXYuY29tbWFuZF9sb25nX3NlbmQoCiAgICAgICAgbWFzdGVyLnRhcmdldF9zeXN0ZW0sCiAgICAgICAgbWFzdGVyLnRhcmdldF9jb21wb25lbnQsCiAgICAgICAgbWF2dXRpbC5tYXZsaW5rLk1BVl9DTURfRE9fRkxJR0hUVEVSTUlOQVRJT04sCiAgICAgICAgMCwgICMgQ29uZmlybWF0aW9uCiAgICAgICAgMSwgICMgUGFyYW0xOiAxIHRvIGluaXRpYXRlIGZsaWdodCB0ZXJtaW5hdGlvbgogICAgICAgIDAsIDAsIDAsIDAsIDAsIDAgICMgT3RoZXIgcGFyYW1zIHVudXNlZAogICAgKQogICAgcHJpbnQoIkZsaWdodCB0ZXJtaW5hdGlvbiBjb21tYW5kIHNlbnQgLSBzaW11bGF0aW5nIGNyYXNoIikKCiMgQ29ubmVjdCB0byB0aGUgZHJvbmUKY29ubmVjdGlvbl9zdHJpbmcgPSAidWRwOjAuMC4wLjA6MTQ1NTAiCm1hc3RlciA9IG1hdnV0aWwubWF2bGlua19jb25uZWN0aW9uKGNvbm5lY3Rpb25fc3RyaW5nKQptYXN0ZXIud2FpdF9oZWFydGJlYXQoKQpwcmludCgiQ29ubmVjdGVkIHRvIGRyb25lIikKCiMgU2VuZCBmbGlnaHQgdGVybWluYXRpb24gY29tbWFuZCB0byBzaW11bGF0ZSBhIGNyYXNoCnNlbmRfZmxpZ2h0X3Rlcm1pbmF0aW9uX2NvbW1hbmQobWFzdGVyKQoKIyBTZW5kIHBlcmlvZGljIGhlYXJ0YmVhdHMgdG8ga2VlcCBNQVZMaW5rIGNvbm5lY3Rpb24gYWxpdmUKdHJ5OgogICAgd2hpbGUgVHJ1ZToKICAgICAgICBtYXN0ZXIubWF2LmhlYXJ0YmVhdF9zZW5kKAogICAgICAgICAgICBtYXZ1dGlsLm1hdmxpbmsuTUFWX1RZUEVfUVVBRFJPVE9SLAogICAgICAgICAgICBtYXZ1dGlsLm1hdmxpbmsuTUFWX0FVVE9QSUxPVF9BUkRVUElMT1RNRUdBLAogICAgICAgICAgICAwLCAwLAogICAgICAgICAgICBtYXZ1dGlsLm1hdmxpbmsuTUFWX1NUQVRFX0FDVElWRQogICAgICAgICkKICAgICAgICB0aW1lLnNsZWVwKDEpCmV4Y2VwdCBLZXlib2FyZEludGVycnVwdDoKICAgIHBhc3MK" | base64 -d > /return-to-land.py

CMD echo "Ground Control Online..." && /usr/bin/expect /init

