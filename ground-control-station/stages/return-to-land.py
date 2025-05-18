import sys
import os
sys.path.insert(0, "/custom_mavlink")
print("PYTHONPATH:", sys.path)
from custom_mavlink import mavutils
import time

def set_rtl_altitude(master, rtl_alt_cm):
    """Set the RTL altitude."""
    master.param_set_send('RTL_ALT', rtl_alt_cm, mavutils.mavlink.MAV_PARAM_TYPE_INT32)
    # Wait for the parameter to be set
    time.sleep(2)

def set_mode_rtl(master):
    """Set the drone's mode to RTL (Return to Launch)."""
    master.mav.set_mode_send(
        master.target_system,
        mavutils.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
        mavutils.mavlink.COPTER_MODE_RTL
    )

# Connect to the drone
connection_string = "udp:0.0.0.0:14550"  # Replace with your connection string
master = mavutils.mavlink_connection(connection_string)
master.wait_heartbeat()
print("Connected to drone")

# Set RTL altitude (e.g., 5000 cm for 50 meters)
set_rtl_altitude(master, 275)
print("RTL altitude set to 50 meters")

# Set mode to RTL
set_mode_rtl(master)
print("Returning to Launch")