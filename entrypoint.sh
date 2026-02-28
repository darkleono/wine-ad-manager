#!/bin/bash
# entrypoint.sh

# Ensure there's a license file
if [ ! -f /var/flexlm/licenses.lic ]; then
    echo "ERROR: No license file found at /var/flexlm/licenses.lic"
    exit 1
fi

# Link the adskflex vendor daemon if it's in the same directory
# Sometimes needed for FlexNet to find it
cd /opt/flexnetserver

# Start the license manager in the foreground (-z)
# -c specifies the license file
# -l specifies the log (optional, but good for debugging)
echo "Starting Autodesk Network License Manager..."
./lmgrd -z -c /var/flexlm/licenses.lic
