#!/bin/env sh

# Check if Waybar is running
if pgrep waybar > /dev/null; then
    pkill waybar
    # Wait a moment for Waybar to terminate
    sleep 1
fi

waybar &> ~/.waybar.log &
