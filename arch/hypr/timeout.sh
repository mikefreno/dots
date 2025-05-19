#!/bin/env sh
IFS=' ' read -ra brightness <<< $(ddcutil getvcp 10 --terse)
echo ${brightness[3]} > /tmp/brightness-timeout
echo 'min' > /tmp/waybar-ddc-module-rx
exit 0
