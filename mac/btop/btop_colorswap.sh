#!/bin/bash
cd ~/.config/btop

darkmode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
rm btop.conf
if [[ $darkmode == "Dark" ]]; then
    cp btop_dark btop.conf
else
    cp btop_light btop.conf
fi

