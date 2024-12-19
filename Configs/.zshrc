# Oh-my-zsh installation path
ZSH=$HOME/.oh-my-zsh

# Powerlevel10k theme path
source $ZSH/themes/powerlevel10k/powerlevel10k.zsh-theme

# List of plugins used
plugins=()
source $ZSH/oh-my-zsh.sh

# In case a command is not found, try to find the package that has it
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( $(apt-file search -- "$1") )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( $entry )
            if [[ "$pkg" != "${fields[0]}" ]]; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[0]}" "${fields[1]}" "${fields[2]}"
            fi
            pkg="${fields[0]}"
        done
    fi
    return 127
}

# Function to install packages from APT and PPA (Ubuntu)
function in {
    local -a inPkg=("$@")
    local -a aptPkgs=()

    for pkg in "${inPkg[@]}"; do
        if apt-cache show "$pkg" &>/dev/null; then
            aptPkgs+=("${pkg}")
        else
            echo "Package $pkg not found in APT repositories"
        fi
    done

    if [[ ${#aptPkgs[@]} -gt 0 ]]; then
        sudo apt install "${aptPkgs[@]}"
    fi
}

# Helpful aliases
alias c='clear' # clear terminal
alias l='ls -lh --color=auto' # long list
alias ls='ls -1 --color=auto' # short list
alias ll='ls -lha --color=auto --sort=name --group-directories-first' # long list all
alias ld='ls -lhD --color=auto' # long list dirs
alias lt='ls --color=auto --tree' # list folder as tree
alias un='sudo apt remove --purge' # uninstall package
alias up='sudo apt update && sudo apt upgrade' # update system/package
alias pl='dpkg -l' # list installed packages
alias pa='apt-cache search' # list available package
alias pc='sudo apt autoremove' # remove unused cache
alias po='sudo apt-get autoremove --purge' # remove unused packages
alias vc='code' # gui code editor

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
alias mkdir='mkdir -p'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Display Pokemon (ensure pokemon-colorscripts is installed)
#pokemon-colorscripts --no-title -r 1,3,6

# Created by `pipx` on 2024-12-14 20:51:16
export PATH="$PATH:/home/adi/.local/bin"
