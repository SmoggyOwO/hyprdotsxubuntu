#!/usr/bin/env bash

#|---/ /+-----------------------------------------------+---/ /|#
#|--/ /-| Script to enable early loading for nvidia drm |--/ /-|#
#|-/ /--| Adapted for ubuntu                            |-/ /--|#
#|/ /---+-----------------------------------------------+/ /---|#

if [ $(lspci -k | grep -A 2 -E "(VGA|3D)" | grep -i nvidia | wc -l) -gt 0 ]; then
    if [ $(grep 'MODULES=' /etc/default/grub | grep nvidia | wc -l) -eq 0 ]; then
        sudo sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ nvidia-drm.modeset=1\"/" /etc/default/grub
        sudo update-grub
    fi
    if [ $(grep 'options nvidia-drm modeset=1' /etc/modprobe.d/nvidia.conf | wc -l) -eq 0 ]; then
        echo 'options nvidia-drm modeset=1' | sudo tee -a /etc/modprobe.d/nvidia.conf
    fi
    sudo update-initramfs -u
fi
