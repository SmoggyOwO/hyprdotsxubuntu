#!/usr/bin/env bash
#// set variables
scrDir="$(dirname "$(realpath "$0")")"

# Check if globalcontrol.sh exists
if [[ ! -f "${scrDir}/globalcontrol.sh" ]]; then
    echo "Error: globalcontrol.sh not found in ${scrDir}"
    exit 1
fi

# Source the global control script
source "${scrDir}/globalcontrol.sh"

# Dependency checks
command -v rofi >/dev/null 2>&1 || { 
    echo "Error: Rofi is not installed. Please install it using 'sudo apt install rofi'"
    exit 1
}

command -v jq >/dev/null 2>&1 || { 
    echo "Error: jq is not installed. Please install it using 'sudo apt install jq'"
    exit 1
}

command -v hyprctl >/dev/null 2>&1 || { 
    echo "Warning: hyprctl not found. This script is designed for Hyprland."
}

# Fallback variables
rofiConf="${confDir}/rofi/selector.rasi"
rofiStyleDir="${confDir}/rofi/styles"
rofiAssetDir="${confDir}/rofi/assets"

# Set rofi scaling
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"

# Border calculations with fallbacks
hypr_border="${hypr_border:-0}"
elem_border=$(( hypr_border * 5 ))
icon_border=$(( elem_border - 5 ))

# Monitor resolution and scaling
# Fallback to default values if hyprctl fails
mon_x_res=$(hyprctl -j monitors 2>/dev/null | jq '.[] | select(.focused==true) | .width' || echo 1920)
mon_scale=$(hyprctl -j monitors 2>/dev/null | jq '.[] | select(.focused==true) | .scale' 2>/dev/null | sed "s/\.//;" || echo 100)
mon_x_res=$(( mon_x_res * 100 / mon_scale ))

# Generate config
elm_width=$(( (20 + 12 + 16 ) * rofiScale ))
max_avail=$(( mon_x_res - (4 * rofiScale) ))
col_count=$(( max_avail / elm_width ))
[[ "${col_count}" -gt 5 ]] && col_count=5

r_override="window{width:100%;} listview{columns:${col_count};} element{orientation:vertical;border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:20em;} element-text{enabled:false;}"

# Validate directories
[[ ! -d "${rofiStyleDir}" ]] && { 
    echo "Error: Rofi style directory not found: ${rofiStyleDir}"
    exit 1
}

[[ ! -d "${rofiAssetDir}" ]] && { 
    echo "Error: Rofi asset directory not found: ${rofiAssetDir}"
    exit 1
}

# Launch rofi menu
RofiSel=$(ls "${rofiStyleDir}"/style_*.rasi 2>/dev/null | awk -F '[_.]' '{print $((NF - 1))}' | while read -r styleNum
do
    echo -en "${styleNum}\x00icon\x1f${rofiAssetDir}/style_${styleNum}.png\n"
done | sort -n | rofi -dmenu -theme-str "${r_scale}" -theme-str "${r_override}" -config "${rofiConf}" -select "${rofiStyle}")

# Apply rofi style
if [[ -n "${RofiSel}" ]]; then
    # Check if set_conf function exists
    if type set_conf >/dev/null 2>&1; then
        set_conf "rofiStyle" "${RofiSel}"
    else
        echo "Warning: set_conf function not found. Unable to save style."
    fi

    # Check if notify-send is available
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "t1" -r 91190 -t 2200 -i "${rofiAssetDir}/style_${RofiSel}.png" " style ${RofiSel} applied..."
    else
        echo "Style ${RofiSel} applied (notify-send not available)"
    fi
fi