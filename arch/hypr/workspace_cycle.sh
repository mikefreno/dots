#!/bin/bash

current_workspace=$(hyprctl -j activeworkspace | jq -r '.id')
current_monitor=$(hyprctl -j activeworkspace | jq -r '.monitorID')


workspace_ids_current_monitor=$(hyprctl -j workspaces | jq --arg currentMonitorID "$current_monitor" -r '
  .[] | select(.monitorID == ($currentMonitorID | tonumber)) | .id'
)

readarray -t workspace_ids_current_monitor <<< "$workspace_ids_current_monitor"

if [[ "$1" == "-" ]]; then
  if [[ "$current_workspace" == "${workspace_ids_current_monitor[0]}" ]]; then
    new_workspace=${workspace_ids_current_monitor[-1]}
  else
    new_workspace=$((current_workspace - 1))
  fi
elif [[ "$1" == "+" ]]; then
  echo "Debug: Moving to next workspace..."
  if [[ "$current_workspace" == "${workspace_ids_current_monitor[-1]}" ]]; then
    new_workspace=${workspace_ids_current_monitor[0]}
  else
    new_workspace=$((current_workspace + 1))
  fi
fi

hyprctl dispatch workspace "$new_workspace"
