#!/bin/env sh
restore_val=$(tail -n 1 /tmp/brightness-timeout)
echo $restore_val > /tmp/waybar-ddc-module-rx
exit 0
