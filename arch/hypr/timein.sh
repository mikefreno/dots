#!/bin/env sh
restore_val=$(tail -n 1 /tmp/brightness-timeout)
qs -c noctalia-shell ipc call brightness set $restore_val
exit 0
