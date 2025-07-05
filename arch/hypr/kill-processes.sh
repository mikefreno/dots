#!/bin/bash
SAVE_FILE="/home/mike/.config/hypr/kill.log"

> "$SAVE_FILE"

# Special cases where the class does not correspond the command
declare -A apps_commands=(
    [org.gnome.Podcasts]="gnome-podcasts"
    [zen]="zen-browser"
    [com.mitchellh.ghostty]="ghostty"
)

hyprctl clients | grep 'class:' | cut -d' ' -f2- | while IFS= read -r class; do
    if [[ "${apps_commands[$class]}" ]]; then
        cmd="${apps_commands[$class]}"
    else
        cmd="$class"
    fi

    echo "Killing process with Class: $class (Command: $cmd)"
    pkill -f "$cmd"

    echo "$cmd" >> "$SAVE_FILE"
done

echo "All graphical windowed processes have been killed and classes saved to $SAVE_FILE."
