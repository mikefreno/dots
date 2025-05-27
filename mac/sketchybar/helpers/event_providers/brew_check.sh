#!/bin/bash

# Run brew outdated in background and cache result
CACHE_FILE="/tmp/brew_outdated_count"
LOCK_FILE="/tmp/brew_check.lock"

# Check if already running
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# Create lock file
touch "$LOCK_FILE"

# Get count and cache it
COUNT=$(brew outdated --quiet | wc -l | tr -d ' ')
echo "$COUNT" > "$CACHE_FILE"

# Trigger sketchybar update
sketchybar --trigger brew_update

# Remove lock file
rm -f "$LOCK_FILE"
