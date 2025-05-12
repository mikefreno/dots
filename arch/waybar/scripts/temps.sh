#!/usr/bin/env bash

#modified to include GPU info - nvidia only
cpu_model=$(awk -F ': ' '/model name/{print $2}' /proc/cpuinfo | head -n 1 | sed 's/@.*//; s/ *\((R)\|(TM)\)//g; s/^[ \t]*//; s/[ \t]*$//')
gpu_model=$(nvidia-smi --query-gpu name --format=csv,noheader)

# get CPU clock speeds
get_cpu_frequency() {
  freqlist=$(awk '/cpu MHz/ {print $4}' /proc/cpuinfo)
  maxfreq=$(sed 's/...$//' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
  if [ -z "$freqlist" ] || [ -z "$maxfreq" ]; then
    echo "--"
    return
  fi
  average_freq=$(echo "$freqlist" | tr ' ' '\n' | awk "{sum+=\$1} END {printf \"%.0f/%s MHz\", sum/NR, $maxfreq}")
  echo "$average_freq"
}

get_gpu_frequency(){
  IFS=", "
  read -r currentfreq maxfreq <<< $(nvidia-smi --query-gpu=clocks.gr,clocks.max.gr --format=csv,nounits,noheader)
  echo "$currentfreq/$maxfreq MHz"
}

# get CPU temp
get_cpu_temperature() {
  temp=$(sensors | awk '/Package id 0/ {print $4}' | awk -F '[+.]' '{print $2}')
  if [[ -z "$temp" ]]; then
    temp=$(sensors | awk '/Tctl/ {print $2}' | tr -d '+°C')
  fi
  if [[ -z "$temp" ]]; then
    temp="--"
    temp_f="--"
  else
    temp=${temp%.*}
    temp_f=$(awk "BEGIN {printf \"%.1f\", ($temp * 9 / 5) + 32}")
  fi
  # Celsius and Fahrenheit
  echo "${temp:---} ${temp_f:---}"
}

get_gpu_temperature(){
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,nounits,noheader)
  temp_f=$(awk "BEGIN {printf \"%.1f\", ($temp * 9 / 5) + 32}")
  echo "${temp:---} ${temp_f:---}"
}

get_temperature_icon() {
  temp_value=$1
  if [ "$temp_value" = "--" ]; then
    icon="󱔱" # none
  elif [ "$temp_value" -ge 80 ]; then
    icon="󰸁" # high
  elif [ "$temp_value" -ge 70 ]; then
    icon="󱃂" # medium
  elif [ "$temp_value" -ge 60 ]; then
    icon="󰔏" # normal
  else
    icon="󱃃" # low
  fi
  echo "$icon"
}

cpu_frequency=$(get_cpu_frequency)
gpu_frequency=$(get_gpu_frequency)
read -r cpu_temp_info < <(get_cpu_temperature)
read -r gpu_temp_info < <(get_gpu_temperature)
cpu_temp=$(echo "$cpu_temp_info" | awk '{print $1}')
cpu_temp_f=$(echo "$cpu_temp_info" | awk '{print $2}')
gpu_temp=$(echo "$gpu_temp_info" | awk '{print $1}')
gpu_temp_f=$(echo "$gpu_temp_info" | awk '{print $2}')
thermo_icon=$(get_temperature_icon "$temp")
# high temp warning
if [ "$cpu_temp" == "--" ] || [ "$cpu_temp" -ge 80 ]; then
  cpu_text_output="<span color='#f38ba8'>${thermo_icon} ${cpu_temp}°C</span>"
else
  cpu_text_output="${thermo_icon} ${cpu_temp}°C"
fi
if [ "$gpu_temp" == "--" ] || [ "$gpu_temp" -ge 80 ]; then
  gpu_text_output="<span color='#f38ba8'>${thermo_icon} ${gpu_temp}°C</span>"
else
  gpu_text_output="${thermo_icon} ${gpu_temp}°C"
fi

tooltip=":: ${cpu_model}\n"
tooltip+="Clock Speed: ${cpu_frequency}\nTemperature: ${cpu_temp_f}°F"
tooltip+="\n:: ${gpu_model}\n"
tooltip+="Clock Speed: ${gpu_frequency}\nTemperature: ${gpu_temp_f}°F"

# module and tooltip
echo "{\"text\": \"$cpu_text_output | $gpu_text_output\", \"tooltip\": \"$tooltip\"}"
