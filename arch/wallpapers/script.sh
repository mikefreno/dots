#!/bin/bash
declare -a wallpapers=("33_paintress.jpeg" "abstract.jpg" "city.jpg" "cyber.jpg" "frieren.png" "nature_forest.jpg" "street.jpg")

declare -a positions=('top-left' 'top-right' 'center' 'bottom-right' 'bottom-left' )


while true; do
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
    random_position="${positions[$((RANDOM % ${#positions[@]}))]}"
    swww img ~/.config/wallpapers/$random_img --transition-type grow --transition-pos $random_position --transition-fps 144
    # sleep for 1 hour
    sleep 3600
done
