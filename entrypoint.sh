#!/bin/bash
# entrypoint.sh
echo "127.0.0.1 license-server" >> /etc/hosts

# Ensure there's a license file
if [ ! -f /var/flexlm/licenses.lic ]; then
    echo "ERROR: No license file found at /var/flexlm/licenses.lic"
    exit 1
fi

# Update license file hostname and hostid if it exists
if [ -f "/var/flexlm/licenses.lic" ]; then
    echo "Configuring license file..."
    CURRENT_HOSTID=$(cat /sys/class/net/eth0/address | sed 's/://g')
    echo "Current HostID (MAC): $CURRENT_HOSTID"
    # Update hostname and HostID in the first line
    # Format: SERVER hostname hostid port
    sed -i "1s/SERVER [^ ]* [^ ]*/SERVER $(hostname) $CURRENT_HOSTID/" /var/flexlm/licenses.lic
fi

# Link the adskflex vendor daemon if it's in the same directory
# Sometimes needed for FlexNet to find it
cd /opt/flexnetserver/

# Start the Web Dashboard in the background
echo "Starting Web Dashboard on port 8080..."
python3 /opt/dashboard/app.py &

# Start the license manager in the foreground (-z)
# -c specifies the license file
# -l specifies the log (optional, but good for debugging)
echo "Starting Autodesk Network License Manager..."
# Use -l to keep logs reachable, but -z to stream to stdout if desired
# Here we use -z but also redirect to a log so dashboard can read if needed? 
# Dashboard reads via lmutil, so it doesn't need the log file directly.
exec ./lmgrd -z -c /var/flexlm/licenses.lic
