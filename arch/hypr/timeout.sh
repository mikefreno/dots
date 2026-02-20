
#!/bin/env sh
IFS=' ' read -ra brightness <<< $(ddcutil getvcp 10 --terse)
echo ${brightness[3]} > /tmp/brightness-timeout
qs -c noctalia-shell ipc call brightness set 20
exit 0
