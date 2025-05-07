#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title colorswap
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author MikeFreno


#!/bin/bash

# Initialize last known state from a state file
STATE_FILE="$HOME/.config/theme_state"
if [[ -f "$STATE_FILE" ]]; then
    LAST_MODE=$(cat "$STATE_FILE")
else
    LAST_MODE="unknown"
fi

while true; do
    isDarkMode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
    CURRENT_MODE=${isDarkMode:-Light}

    # Only proceed if the mode has changed
    if [[ "$CURRENT_MODE" != "$LAST_MODE" ]]; then
        echo "Mode changed from $LAST_MODE to $CURRENT_MODE"

        config_dir="$HOME/.config/kitty"
        kitty_file="$config_dir/kitty.conf"
        kitty_dark_file="$config_dir/kitty_dark.conf"
        kitty_light_file="$config_dir/kitty_light.conf"

        if [[ $isDarkMode == "Dark" ]]; then
            cp "$kitty_dark_file" "$kitty_file"
            kitty @ load-config
            echo "Switched kitty to dark mode"
        else
            cp "$kitty_light_file" "$kitty_file"
            kitty @ load-config
            echo "Switched kitty to light mode"
        fi

        config_dir="$HOME/.config/borders"
        borders_file="$config_dir/bordersrc"
        borders_dark_file="$config_dir/bordersrc_dark"
        borders_light_file="$config_dir/bordersrc_light"

        if [[ $isDarkMode == "Dark" ]]; then
            cp "$borders_dark_file" "$borders_file"
            echo "Switched borders to dark mode"
        else
            cp "$borders_light_file" "$borders_file"
            echo "Switched borders to light mode"
        fi

        config_dir="$HOME/.config/sketchybar"
        colors_file="$config_dir/colors.lua"
        colors_dark_file="$config_dir/colors_dark.lua"
        colors_light_file="$config_dir/colors_light.lua"

        if [[ $isDarkMode == "Dark" ]]; then
            cp "$colors_dark_file" "$colors_file"
            brew services restart sketchybar
            yabai --restart-service
            echo "Switched sketchybar to dark mode"
        else
            cp "$colors_light_file" "$colors_file"
            brew services restart sketchybar
            yabai --restart-service
            echo "Switched sketchybar to light mode"
        fi

        echo "$CURRENT_MODE" > "$STATE_FILE"
        LAST_MODE="$CURRENT_MODE"
        
        echo "Theme switch completed at $(date)"
    fi

    sleep 10
done
