#!/usr/bin/env bash

#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|-/ /--| Adapted for Ubuntu                   |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"

if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Function for timed prompt
prompt_timer() {
    local timeout=$1
    local prompt_text=$2
    local prompt_result
    
    echo -ne "\r$prompt_text "
    read -t "$timeout" prompt_result
    
    if [ $? -eq 0 ]; then
        promptIn=$prompt_result
    else
        promptIn="y"
        echo # Add newline since read timed out
    fi
}

#SDDM Configuration
if pkg_installed sddm; then
    echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m detected // sddm"

    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi

    if [ ! -f /etc/sddm.conf.d/kde_settings.t2.bkp ]; then
        echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m configuring sddm..."
        echo -e "Select sddm theme:\n[1] Candy\n[2] Corners"
        read -p " :: Enter option number : " sddmopt

        case $sddmopt in
            1) sddmtheme="Candy" ;;
            *) sddmtheme="Corners" ;;
        esac

        # Check if themes directory exists, create if not
        sudo mkdir -p /usr/share/sddm/themes/

        # Extract theme
        sudo tar -xzf "${scrDir}/../Source/arcs/Sddm_${sddmtheme}.tar.gz" -C /usr/share/sddm/themes/

        # Create and backup config
        sudo touch /etc/sddm.conf.d/kde_settings.conf
        sudo cp /etc/sddm.conf.d/kde_settings.conf /etc/sddm.conf.d/kde_settings.t2.bkp
        sudo cp /usr/share/sddm/themes/${sddmtheme}/kde_settings.conf /etc/sddm.conf.d/
    else
        echo -e "\033[0;33m[SKIP]\033[0m sddm is already configured..."
    fi

    # Set user avatar
    if [ ! -f /usr/share/sddm/faces/${USER}.face.icon ] && [ -f "${scrDir}/Source/misc/${USER}.face.icon" ]; then
        sudo mkdir -p /usr/share/sddm/faces/
        sudo cp "${scrDir}/Source/misc/${USER}.face.icon" /usr/share/sddm/faces/
        echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m avatar set for ${USER}..."
    fi
else
    echo -e "\033[0;33m[WARNING]\033[0m sddm is not installed..."
fi

#Dolphin Configuration
if pkg_installed dolphin && pkg_installed xdg-utils; then
    echo -e "\033[0;32m[FILEMANAGER]\033[0m detected // dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    echo -e "\033[0;32m[FILEMANAGER]\033[0m setting $(xdg-mime query default "inode/directory") as default file explorer..."
else
    echo -e "\033[0;33m[WARNING]\033[0m dolphin is not installed..."
fi

# Shell Configuration
if [ -f "${scrDir}/restore_shl.sh" ]; then
    "${scrDir}/restore_shl.sh"
else
    echo -e "\033[0;33m[WARNING]\033[0m shell restore script not found..."
fi

# Flatpak Configuration
if ! pkg_installed flatpak; then
    # Install flatpak if not present
    echo -e "\033[0;32m[FLATPAK]\033[0m Installing flatpak..."
    sudo apt-get update && sudo apt-get install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    echo -e "\033[0;32m[FLATPAK]\033[0m flatpak application list..."
    if [ -f "${scrDir}/.extra/custom_flat.lst" ]; then
        awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/.extra/custom_flat.lst"
        prompt_timer 60 "Install these flatpaks? [Y/n]"
        fpkopt=${promptIn,,}
        
        if [ "${fpkopt}" = "y" ]; then
            echo -e "\033[0;32m[FLATPAK]\033[0m installing flatpaks..."
            "${scrDir}/.extra/install_fpk.sh"
        else
            echo -e "\033[0;33m[SKIP]\033[0m installing flatpaks..."
        fi
    else
        echo -e "\033[0;33m[WARNING]\033[0m flatpak list file not found..."
    fi
else
    echo -e "\033[0;33m[SKIP]\033[0m flatpak is already installed..."
fi
