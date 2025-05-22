#!/bin/bash
declare -a wallpapers=("33_paintress.jpeg" "abstract.jpg" "city.jpg" "cyber.jpg" "cyber_2.jpg" "cyberpunk_1.png" "cyberpunk_2.png" "frieren.png" "nature_forest.jpg" "nature_river.jpg" "painted.jpg" "painted_2.jpg" "street.jpg")

declare -a positions=('top-left' 'top-right' 'center' 'bottom-right' 'bottom-left' )

if pgrep -x "wallpaper_script" > /dev/null; then
    exit 0
fi

while true; do
    if ! pgrep -x "swww-daemon" > /dev/null; then
        swww-daemon &>/dev/null
        sleep 1
    fi
    # get current wallpaper
    declare query=`swww query`
    IFS='/' read -r -a split <<< $query
    declare curr="${split[-1]}"

    # filter the current wallpaper
    filtered_wallpapers=()
    for img in "${wallpapers[@]}"; do
        if [[ ! "$img" =~ "$curr" ]]; then
            filtered_wallpapers+=("$img")
        fi
    done

    # select random image, that is not the current
    random_img="${filtered_wallpapers[$((RANDOM % ${#filtered_wallpapers[@]}))]}"
    echo ~/.config/wallpapers/$random_img > /tmp/current_wallpaper
    random_position="${positions[$((RANDOM % ${#positions[@]}))]}"
    swww img ~/.config/wallpapers/$random_img --transition-type grow --transition-pos $random_position --transition-fps 144
    # sleep for 15 min
    sleep 900
done
