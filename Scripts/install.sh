#!/usr/bin/env bash

#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| Adapted for Ubuntu       |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat << "EOF"

-------------------------------------------------
        .
       / \         _       _  _      ___  ___ 
      /^  \      _| |_    | || |_  _|   \| __|
     /  _  \    |_   _|   | __ | || | |) | _| 
    /  | | ~\     |_|     |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/          

-------------------------------------------------

EOF

#--------------------------------#
# Import variables and functions #
#--------------------------------#

export scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#------------------#
# Evaluate options #
#------------------#

flg_Install=0
flg_Restore=0
flg_Service=0

while getopts idrs RunStep; do
    case $RunStep in
        i)  flg_Install=1 ;;
        d)  flg_Install=1 ; export use_default="--assume-yes" ;;
        r)  flg_Restore=1 ;;
        s)  flg_Service=1 ;;
        *)  echo "...valid options are..."
            echo "i : [i]nstall packages without configs"
            echo "d : install packages with [d]efaults --assume-yes"
            echo "r : [r]estore config files"
            echo "s : enable system [s]ervices"
            exit 1 ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
fi

#--------------------#
# Pre-install script #
#--------------------#

if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|


EOF

    "${scrDir}/install_pre.sh"
fi

#------------#
# Installing #
#------------#

if [ ${flg_Install} -eq 1 ]; then
    cat << "EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # Build packages       #
    #----------------------#

    "${scrDir}/build_pkg.sh"

    #----------------------#
    # Prepare package list #
    #----------------------#
    
    shift $((OPTIND - 1))
    cust_pkg=$1
    cp "${scrDir}/custom_hypr.lst" "${scrDir}/install_pkg.lst"

    if [ -f "${cust_pkg}" ] && [ ! -z "${cust_pkg}" ]; then
        cat "${cust_pkg}" >> "${scrDir}/install_pkg.lst"
    fi

    if ! chk_list "myShell" "${shlList[@]}"; then
        echo -e "Select shell:\n[1] zsh\n[2] fish"
        prompt_timer 120 "Enter option number"

        case "${promptIn}" in
            1) export myShell="zsh" ;;
            2) export myShell="fish" ;;
            *) echo -e "...Invalid option selected..." ; exit 1 ;;
        esac
        echo "${myShell}" >> "${scrDir}/install_pkg.lst"
    fi

    #----------------------#
    # Install packages     #
    #----------------------#
    
    sudo apt update
    "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
    rm "${scrDir}/install_pkg.lst"
fi

#---------------------------#
# Restore custom configs    #
#---------------------------#

if [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"

             _           _
 ___ ___ ___| |_ ___ ___|_|___ ___
|  _| -_|_ -|  _| . |  _| |   | . |
|_| |___|___|_| |___|_| |_|_|_|_  |
                              |___|

EOF

    "${scrDir}/restore_fnt.sh"
    "${scrDir}/restore_cfg.sh"
    echo -e "\n\033[0;32m[themepatcher]\033[0m Patching themes..."

    while IFS='"' read -r null1 themeName null2 themeRepo; do
        themeNameQ+=("${themeName//\"/}")
        themeRepoQ+=("${themeRepo//\"/}")
        themePath="${confDir}/hyde/themes/${themeName}"
        [ -d "${themePath}" ] || mkdir -p "${themePath}"
        [ -f "${themePath}/.sort" ] || echo "${#themeNameQ[@]}" > "${themePath}/.sort"
    done < "${scrDir}/themepatcher.lst"

    if parallel --bar --link "${scrDir}/themepatcher.sh" "{1}" "{2}" "{3}" "{4}" ::: "${themeNameQ[@]}" ::: "${themeRepoQ[@]}" ::: "--skipcaching" ::: "false"; then
        echo "Themes patched successfully"
    fi

    echo -e "\n\033[0;32m[cache]\033[0m Generating cache files..."
    "$HOME/.local/share/bin/swwwallcache.sh" -t ""

    if printenv HYPRLAND_INSTANCE_SIGNATURE &> /dev/null; then
        "$HOME/.local/share/bin/themeswitch.sh" &> /dev/null
    fi
fi

#---------------------#
# Post-install script #
#---------------------#

if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|


EOF

    "${scrDir}/install_pst.sh"
fi

#------------------------#
# Enable system services #
#------------------------#

if [ ${flg_Service} -eq 1 ]; then
    cat << "EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|


EOF

    while read servChk; do
        if [[ $(systemctl list-units --all -t service --full --no-legend "${servChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${servChk}.service" ]]; then
            echo -e "\033[0;33m[SKIP]\033[0m ${servChk} service is active..."
        else
            echo -e "\033[0;32m[systemctl]\033[0m Starting ${servChk} system service..."
            sudo systemctl enable "${servChk}.service"
            sudo systemctl start "${servChk}.service"
        fi
    done < "${scrDir}/system_ctl.lst"
fi
