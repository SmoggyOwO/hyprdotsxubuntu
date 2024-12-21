#!/usr/bin/env bash

#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre install configs |--/ /-|#
#|-/ /--| Adapted for Ubuntu                  |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"

if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# GRUB configuration
if pkg_installed grub-common && [ -f /boot/grub/grub.cfg ]; then
    echo -e "\033[0;32m[BOOTLOADER]\033[0m detected // grub"
    
    if [ ! -f /etc/default/grub.t2.bkp ] && [ ! -f /boot/grub/grub.t2.bkp ]; then
        echo -e "\033[0;32m[BOOTLOADER]\033[0m configuring grub..."
        sudo cp /etc/default/grub /etc/default/grub.t2.bkp
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.t2.bkp
        
        if nvidia_detect; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m nvidia detected, adding nvidia-drm.modeset=1 to boot option..."
            gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d'"' -f2 | sed 's/\b nvidia-drm.modeset=.\b//g')
            sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia-drm.modeset=1\"" /etc/default/grub
        fi

        echo -e "Select grub theme:\n[1] Retroboot (dark)\n[2] Pochita (light)"
        read -p " :: Press enter to skip grub theme <or> Enter option number : " grubopt
        
        case ${grubopt} in
            1) grubtheme="Retroboot" ;;
            2) grubtheme="Pochita" ;;
            *) grubtheme="None" ;;
        esac

        if [ "${grubtheme}" == "None" ]; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Skipping grub theme..."
            sudo sed -i "s/^GRUB_THEME=/#GRUB_THEME=/g" /etc/default/grub
        else
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Setting grub theme // ${grubtheme}"
            # Ensure grub themes directory exists
            sudo mkdir -p /usr/share/grub/themes/
            sudo tar -xzf ${cloneDir}/Source/arcs/Grub_${grubtheme}.tar.gz -C /usr/share/grub/themes/
            sudo sed -i "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved
            /^GRUB_GFXMODE=/c\GRUB_GFXMODE=1280x1024x32,auto
            /^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" /etc/default/grub
        fi
        
        sudo update-grub
    else
        echo -e "\033[0;33m[SKIP]\033[0m grub is already configured..."
    fi
fi

# Systemd-boot configuration
if pkg_installed systemd && nvidia_detect; then
    bootctl_output=$(bootctl status 2> /dev/null | awk '{if ($1 == "Product:") print $2}')
    
    if [ "$bootctl_output" = "systemd-boot" ]; then
        echo -e "\033[0;32m[BOOTLOADER]\033[0m detected // systemd-boot"

        # Check if backup files match the number of config files
        if [ $(ls -l /boot/loader/entries/*.conf.t2.bkp 2> /dev/null | wc -l) -ne $(ls -l /boot/loader/entries/*.conf 2> /dev/null | wc -l) ]; then
            echo "NVIDIA detected, adding nvidia_drm.modeset=1 to boot option..."
            
            # Process all .conf files in /boot/loader/entries/
            find /boot/loader/entries/ -type f -name "*.conf" | while read -r imgconf; do
                sudo cp "${imgconf}" "${imgconf}.t2.bkp"
                sdopt=$(grep -w "^options" "${imgconf}" | sed 's/\b quiet\b//g' | sed 's/\b splash\b//g' | sed 's/\b nvidia_drm.modeset=.\b//g')
                sudo sed -i "/^options/c${sdopt} quiet splash nvidia_drm.modeset=1" "${imgconf}"
            done
        else
            echo -e "\033[0;33m[SKIP]\033[0m systemd-boot is already configured..."
        fi
    else
        echo -e "\033[0;31m[ERROR]\033[0m systemd-boot not detected or bootctl output is empty."
    fi
else
    echo -e "\033[0;31m[ERROR]\033[0m systemd or NVIDIA driver not detected."
fi

# APT configuration
if [ -f /etc/apt/apt.conf.d/99custom ] && [ ! -f /etc/apt/apt.conf.d/99custom.t2.bkp ]; then
    echo -e "\033[0;32m[APT]\033[0m configuring apt settings..."
    sudo cp /etc/apt/apt.conf.d/99custom /etc/apt/apt.conf.d/99custom.t2.bkp 2>/dev/null
    
    # Create custom APT configuration
    echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99custom
    echo 'Acquire::http::Pipeline-Depth "5";' | sudo tee -a /etc/apt/apt.conf.d/99custom
    echo 'Acquire::http::Parallel-Queue-Size "5";' | sudo tee -a /etc/apt/apt.conf.d/99custom
    
    # Update package lists and upgrade system
    sudo apt update
    sudo apt upgrade -y
else
    echo -e "\033[0;33m[SKIP]\033[0m apt is already configured..."
fi
