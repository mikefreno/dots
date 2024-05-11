VPN=$(scutil --nc list | grep Connected | sed -E 's/.*"(.*)".*/\1/')

if [[ $VPN != "" ]]; then
 sketchybar --add item vpn label="$VPN" drawing=on\
            --set vpn icon=􁅏
fi
