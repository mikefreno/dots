#!/bin/bash

# Define the array of applications
apps=(
    "zen-browser"
    "obsidian"
    "gnome-podcasts"
    "thunderbird"
    "steam -pipewire"
    "bitwarden-desktop"
    "discord"
    "Telegram"
    "protonvpn-app"
    "librepods"
)

LOG_FILE="/tmp/startup_apps.log"

# Loop through the array
for app in "${apps[@]}"; do
    # Run command in background, redirect output to log
    # Note: 'eval' is used to handle arguments (like -pipewire) inside the string
    eval "$app > \"$LOG_FILE\" 2>&1 &"
done

echo "Startup script finished. All apps are running in the background."
echo "Check $LOG_FILE for output."
