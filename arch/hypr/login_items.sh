#!/bin/env sh
protonmail-bridge &>/dev/null &
pkill wall_runner.sh
~/.config/wallpapers/wall_runner.sh &>/dev/null &
exit 0
