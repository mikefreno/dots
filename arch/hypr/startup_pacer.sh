#!/bin/bash

LOG_FILE="$HOME/.config/hypr/startup.log"

# Clear the log file at the beginning of the session
> "$LOG_FILE"

# Function to log commands and their output
log_command() {
    local command="$1"
    local description="$2"
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    echo "Starting: $description ($command)" | tee -a "$LOG_FILE"
    echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    eval "$command" &>> "$LOG_FILE" &
    echo "Command '$description' started with PID $!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# High Priority
log_command "hypridle" "Hyprland Idle Manager"
log_command "hyprlock" "Hyprland Lock Screen"


# Middle Priority
echo "========================================" | tee -a "$LOG_FILE"
echo "Starting Middle Priority Commands" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
log_command "swww-daemon" "SWWW Wallpaper Daemon"
sleep 0.2
log_command "swww img $HOME/.config/wallpapers/33_paintress.jpeg" "Set init wallpaper"
#log_command "$HOME/.config/wallpapers/script.sh" "Custom Wallpaper Script"
sleep 0.2
log_command "eww daemon --force-wayland" "Eww Daemon"
sleep 0.2
log_command "waybar" "Waybar Status Bar"
sleep 0.2
log_command "hyprsunset" "Hyprsunset (Screen Temperature)"
sleep 0.2
log_command "pass-secret-service" "Pass Secret Service Integration"
sleep 0.2
log_command "blueman-applet" "Blueman Applet"
sleep 0.2
log_command "dunst" "Dunst Notification Daemon"
sleep 0.2
log_command "sudo nvidia-smi -i 0 -pl 235" "Set Nvidia Power Limit"
sleep 1

# Low Priority
echo "========================================" | tee -a "$LOG_FILE"
echo "Starting Low Priority Commands" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

log_command "kitty" "Kitty Terminal Emulator"
sleep 0.1
log_command "zen-browser" "Zen Browser"
sleep 0.1
log_command "protonmail-bridge" "ProtonMail Bridge"
sleep 0.1
log_command "gnome-podcasts" "GNOME Podcasts"
sleep 0.1
log_command "thunderbird" "Thunderbird"
sleep 0.1
log_command "discord" "Discord"
sleep 0.1
log_command "flatpak run com.protonvpn.www" "ProtonVPN (Flatpak)"
sleep 0.1
log_command "kidex" "Kidex"
