#!/bin/bash
declare -a BLOCKED_TITLES=(
    "Path of Exile 2"
    "Witchfire"
)

# Get current window title safely
current_title="$(hyprctl activewindow -j | jq -r '.title')"
if [[ $? -ne 0 ]] || [[ -z "$current_title" ]]; then
    echo "Error getting window title"
    exit 1
fi

# Check if current window is blocked
for blocked in "${BLOCKED_TITLES[@]}"; do
    if [[ "$current_title" == *"$blocked"* ]]; then
        # If we're on a blocked window, don't change workspaces
        echo "Current window is blocked: $current_title"
        exit 0
    fi
done

# Get workspace information safely
current_workspace=$(hyprctl -j activeworkspace | jq -r '.id')
current_monitor=$(hyprctl -j activeworkspace | jq -r '.monitorID')

if [[ $? -ne 0 ]] || [[ -z "$current_workspace" ]] || [[ -z "$current_monitor" ]]; then
    echo "Error getting workspace info"
    exit 1
fi

# Get all workspaces for current monitor
workspace_ids_current_monitor=$(hyprctl -j workspaces | jq --arg currentMonitorID "$current_monitor" -r '
  .[] | select(.monitorID == ($currentMonitorID | tonumber)) | .id' | sort -n)

# Convert to array
readarray -t workspace_ids_current_monitor <<< "$workspace_ids_current_monitor"

if [[ ${#workspace_ids_current_monitor[@]} -eq 0 ]]; then
    echo "No workspaces found for monitor"
    exit 1
fi

# Determine new workspace
new_workspace=""
if [[ "$1" == "-" ]]; then
    if [[ "$current_workspace" == "${workspace_ids_current_monitor[0]}" ]]; then
        # Wrap to last workspace
        new_workspace=${workspace_ids_current_monitor[-1]}
    else
        # Move to previous workspace
        current_idx=0
        for i in "${!workspace_ids_current_monitor[@]}"; do
            if [[ "${workspace_ids_current_monitor[$i]}" == "$current_workspace" ]]; then
                current_idx=$i
                break
            fi
        done
        if [[ $current_idx -gt 0 ]]; then
            new_workspace=${workspace_ids_current_monitor[$((current_idx-1))]}
        else
            new_workspace=${workspace_ids_current_monitor[0]}
        fi
    fi
elif [[ "$1" == "+" ]]; then
    echo "Debug: Moving to next workspace..."
    if [[ "$current_workspace" == "${workspace_ids_current_monitor[-1]}" ]]; then
        # Wrap to first workspace
        new_workspace=${workspace_ids_current_monitor[0]}
    else
        # Move to next workspace
        current_idx=0
        for i in "${!workspace_ids_current_monitor[@]}"; do
            if [[ "${workspace_ids_current_monitor[$i]}" == "$current_workspace" ]]; then
                current_idx=$i
                break
            fi
        done
        if [[ $((current_idx+1)) -lt ${#workspace_ids_current_monitor[@]} ]]; then
            new_workspace=${workspace_ids_current_monitor[$((current_idx+1))]}
        else
            new_workspace=${workspace_ids_current_monitor[0]}
        fi
    fi
fi

# Switch to new workspace
if [[ -n "$new_workspace" ]] && [[ "$new_workspace" != "$current_workspace" ]]; then
    echo "Switching from workspace $current_workspace to $new_workspace"
    hyprctl dispatch workspace "$new_workspace"
else
    echo "No workspace change needed or error occurred"
fi
