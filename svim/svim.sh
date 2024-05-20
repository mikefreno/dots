#!/usr/bin/env sh

# This script is executed when either the mode changes,
# or the commandline changes
# This is just an example using sketchybar:
# The variables $MODE and $CMDLINE hold the 
# current editor and cmdline info

# COLOR=0xff9dd274
# if [ "$MODE" = "" ]; then
#   COLOR=0xffff6578
# f
#
 sketchybar --set svim.mode label="[$MODE]" \
                            label.drawing=$(if [ "$MODE" = "" ]; then echo "off"; else echo "on"; fi) \

 sketchybar --add item svim.mode left\
            --set svim.mode popup.align=right \
            --subscribe svim.mode front_app_switched window_focus \
            --add item svim.cmdline popup.svim.mode \
            --set svim.cmdline icon="Command: "

