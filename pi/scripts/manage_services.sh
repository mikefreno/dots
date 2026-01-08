#!/bin/bash

# Script to move service files to /etc/systemd/system/ and enable/start them

echo "Moving service files to /etc/systemd/system/..."

# Copy all service files from service_files directory to /etc/systemd/system/
for file in /Users/mike/dots/pi/service_files/*.service; do
    filename=$(basename "$file")
    echo "Copying $filename..."
    cp "$file" "/etc/systemd/system/$filename"
done

# Reload systemd daemon to recognize new services
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start each service
for file in /Users/mike/dots/pi/service_files/*.service; do
    filename=$(basename "$file")
    servicename="${filename%.service}"
    echo "Enabling and starting $servicename..."
    systemctl enable "$servicename"
    systemctl start "$servicename"
done

echo "All services have been moved, enabled, and started."