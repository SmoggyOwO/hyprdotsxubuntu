#!/usr/bin/env bash

#|---/ /+---------------------------+---/ /|#
#|--/ /-| Script to configure shell |--/ /-|#
#|-/ /--| Adapted for Ubuntu        |-/ /--|#
#|/ /---+---------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Define shell list (assuming this was in global_fn.sh)
shlList=("bash" "zsh")
myShell="zsh"  # Default to zsh, can be changed as needed

if chk_list "${myShell}" "${shlList[@]}"; then
    echo -e "\033[0;32m[SHELL]\033[0m detected // ${myShell}"
else
    echo "Error: user shell not found"
    exit 1
fi

# add zsh plugins
if pkg_installed zsh && [ -d "$HOME/.oh-my-zsh" ]; then
    # set variables
    Zsh_rc="${ZDOTDIR:-$HOME}/.zshrc"
    Zsh_Path="$HOME/.oh-my-zsh"
    Zsh_Plugins="$Zsh_Path/custom/plugins"
    Fix_Completion=""

    # Install oh-my-zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    # generate plugins from list
    while read r_plugin; do
        z_plugin=$(echo "${r_plugin}" | awk -F '/' '{print $NF}')
        if [ "${r_plugin:0:4}" == "http" ] && [ ! -d "${Zsh_Plugins}/${z_plugin}" ]; then
            git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
        fi
        if [ "${z_plugin}" == "zsh-completions" ] && [ "$(grep 'fpath+=.*plugins/zsh-completions/src' "${Zsh_rc}" | wc -l)" -eq 0 ]; then
            Fix_Completion='\nfpath+=${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/zsh-completions/src'
        else
            [ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
        fi
    done < <(cut -d '#' -f 1 "${scrDir}/restore_zsh.lst" | sed 's/ //g')

    # update plugin array in zshrc
    echo -e "\033[0;32m[SHELL]\033[0m installing plugins (${w_plugin} )"
    sed -i "/^plugins=/c\plugins=(${w_plugin} )${Fix_Completion}" "${Zsh_rc}"
fi

# set shell
if [[ "$(grep "/${USER}:" /etc/passwd | awk -F '/' '{print $NF}')" != "${myShell}" ]]; then
    echo -e "\033[0;32m[SHELL]\033[0m changing shell to ${myShell}..."
    sudo chsh -s "$(which "${myShell}")" "$USER"
else
    echo -e "\033[0;33m[SKIP]\033[0m ${myShell} is already set as shell..."
fi
