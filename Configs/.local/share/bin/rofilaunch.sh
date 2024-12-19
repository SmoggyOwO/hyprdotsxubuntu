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

# Fallback configuration if Hyprland variables are not set
hypr_border="${hypr_border:-0}"
hypr_width="${hypr_width:-1}"
rofiStyle="${rofiStyle:-default}"
rofiScale="${rofiScale:-10}"

roconf="${confDir}/rofi/styles/style_${rofiStyle}.rasi"

# Validate rofiScale
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10

# Fallback to first style if specified style not found
if [[ ! -f "${roconf}" ]]; then
    roconf="$(find "${confDir}/rofi/styles" -type f -name "style_*.rasi" | sort -t '_' -k 2 -n | head -1)"
    
    # Additional error handling if no styles found
    if [[ -z "${roconf}" ]]; then
        echo "Error: No Rofi style configurations found"
        exit 1
    fi
fi

# Rofi action
case "${1}" in
    d|--drun) r_mode="drun" ;; 
    w|--window) r_mode="window" ;;
    f|--filebrowser) r_mode="filebrowser" ;;
    h|--help) 
        echo "$(basename "${0}") [action]"
        echo "d, --drun       : Applications menu"
        echo "w, --window     : Window switcher"
        echo "f, --filebrowser: File browser"
        echo "h, --help       : Show this help message"
        exit 0 ;;
    *) r_mode="drun" ;;
esac

# Set overrides
wind_border=$((hypr_border * 3))
elem_border=$((hypr_border == 0 ? 10 : hypr_border * 2))

r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"

# Get icon theme (GNOME specific)
i_override="configuration {icon-theme: \"$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")\";}"

# Dependency checks
command -v rofi >/dev/null 2>&1 || { 
    echo "Error: Rofi is not installed. Please install it using 'sudo apt install rofi'"
    exit 1
}

# Launch rofi
rofi -show "${r_mode}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${i_override}" -config "${roconf}"