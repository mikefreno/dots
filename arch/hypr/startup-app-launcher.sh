#!/bin/bash
sleep 5 # give time for dark/light to adapt to system time

apps=(
    "ghostty"
    "protonmail-bridge"
    "zen-browser"
    "obsidian"
    "gnome-podcasts"
    "thunderbird"
    "steam -pipewire"
    "heroic"
    "bitwarden-desktop"
    "vesktop"
    #"Telegram"
    "protonvpn-app"
    "librepods"
    "docker desktop start"
)

LOG_FILE="/tmp/startup_apps.log"

for app in "${apps[@]}"; do
    eval "$app > \"$LOG_FILE\" 2>&1 &"
done
