#!/bin/bash

SAVE_FILE="/home/mike/.config/hypr/kill.log"

while IFS= read -r class; do
    nohup $class > /dev/null 2>&1 &
done < "$SAVE_FILE"

echo "All graphical windowed processes have been restarted."
