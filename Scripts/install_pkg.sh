#!/usr/bin/env bash

#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| Adapted for Ubuntu                     |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"

if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

listPkg="${1:-"${scrDir}/custom_hypr.lst"}"
aptPkg=()
flatPkg=()
snapPkg=()

# Save original IFS and set new one for reading package list
ofs=$IFS
IFS='|'

# Read and process package list
while read -r pkg deps; do
    pkg="${pkg// /}"
    
    # Skip empty lines
    if [ -z "${pkg}" ]; then
        continue
    fi
    
    # Handle dependencies check
    if [ ! -z "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(echo "${deps}" | xargs -n1)
        
        if [[ ${pass} -ne 1 ]]; then
            echo -e "\033[0;33m[skip]\033[0m ${pkg} is missing (${deps}) dependency..."
            continue
        fi
    fi
    
    # Check if package is already installed
    if pkg_installed "${pkg}"; then
        echo -e "\033[0;33m[skip]\033[0m ${pkg} is already installed..."
        continue
    fi
    
    # Queue package based on availability
    if pkg_available "${pkg}"; then
        # Check package source priority (apt -> flatpak -> snap)
        if apt-cache show "${pkg}" &> /dev/null; then
            echo -e "\033[0;32m[apt]\033[0m queueing ${pkg} from apt repositories..."
            aptPkg+=("${pkg}")
        elif flatpak_available "${pkg}"; then
            echo -e "\033[0;34m[flatpak]\033[0m queueing ${pkg} from flatpak..."
            flatPkg+=("${pkg}")
        elif snap_available "${pkg}"; then
            echo -e "\033[0;35m[snap]\033[0m queueing ${pkg} from snap store..."
            snapPkg+=("${pkg}")
        fi
    else
        echo "Error: unknown package ${pkg}..."
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

# Restore original IFS
IFS=${ofs}

# Install packages in order: apt -> flatpak -> snap
if [[ ${#aptPkg[@]} -gt 0 ]]; then
    echo "Installing apt packages..."
    sudo apt-get update
    sudo apt-get install -y "${aptPkg[@]}"
fi

if [[ ${#flatPkg[@]} -gt 0 ]]; then
    echo "Installing flatpak packages..."
    for pkg in "${flatPkg[@]}"; do
        flatpak install -y "${pkg}"
    done
fi

if [[ ${#snapPkg[@]} -gt 0 ]]; then
    echo "Installing snap packages..."
    for pkg in "${snapPkg[@]}"; do
        sudo snap install "${pkg}"
    done
fi
