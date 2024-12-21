#!/usr/bin/env bash

#|---/ /+---------------------+---/ /|#
#|--/ /-| Global functions    |--/ /-|#
#|-/ /--| Adapted for Ubuntu  |-/ /--|#
#|/ /---+---------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="$HOME/.cache/hyde"
shlList=(zsh fish)

# Define common build directories
buildDirs=(
    "$HOME"           # Common user build directory
)

# Check if required package managers are available
check_package_managers() {
    has_snap=false
    has_flatpak=false

    if command -v snap &>/dev/null; then
        has_snap=true
    fi

    if command -v flatpak &>/dev/null; then
        has_flatpak=true
    fi
}

check_package_managers

# Check if a package is installed via Snap
snap_installed() {
    local pkg=$1
    if $has_snap && snap list "$pkg" &>/dev/null; then
        return 0
    fi
    return 1
}

# Check if a package is available via Snap
snap_available() {
    local pkg=$1
    if $has_snap && snap find "$pkg" 2>/dev/null | grep -q "^$pkg "; then
        return 0
    fi
    return 1
}

# Check if a package is installed via Flatpak
flatpak_installed() {
    local pkg=$1
    if $has_flatpak && flatpak list --app | grep -q "$pkg"; then
        return 0
    fi
    return 1
}

# Check if a package is available via Flatpak
flatpak_available() {
    local pkg=$1
    if $has_flatpak && flatpak search "$pkg" --columns=application | grep -q "^$pkg$"; then
        return 0
    fi
    return 1
}

# Check if a package is installed
pkg_installed() {
    local pkg=$1
    if dpkg -l "$pkg" &>/dev/null || snap_installed "$pkg" || flatpak_installed "$pkg"; then
        return 0
    fi
    return 1
}

# Check if a package is built locally
pkg_built() {
    local pkg=$1

    case "$pkg" in
        zsh)
            command -v zsh &>/dev/null && return 0
            ;;
        oh-my-zsh)
            [ -d "$HOME/.oh-my-zsh" ] && return 0
            ;;
        zsh-theme-powerlevel10k)
            [ -d "$HOME/.oh-my-zsh/themes/powerlevel10k" ] && return 0
            ;;
        pokemon-colorscripts)
            command -v pokemon-colorscripts &>/dev/null && return 0
            ;;
    esac

    for dir in "${buildDirs[@]}"; do
        if [ -d "$dir" ] && find "$dir" -name "${pkg}*.deb" -type f -print -quit | grep -q .; then
            return 0
        fi
    done

    if dpkg -l "$pkg" &>/dev/null && ! apt-cache policy "$pkg" | grep -q "http"; then
        return 0
    fi

    return 1
}

# Check if a package is available in any source
pkg_available() {
    local pkg=$1
    if apt-cache show "$pkg" &>/dev/null || snap_available "$pkg" || flatpak_available "$pkg"; then
        return 0
    fi
    return 1
}

# Check if a dependency is available
dep_available() {
    local pkg=$1
    if pkg_installed "$pkg" || pkg_built "$pkg" || pkg_available "$pkg"; then
        return 0
    fi
    return 1
}

# Get the source of an installed package
get_pkg_source() {
    local pkg=$1
    if dpkg -l "$pkg" &>/dev/null; then
        echo "apt"
    elif snap_installed "$pkg"; then
        echo "snap"
    elif flatpak_installed "$pkg"; then
        echo "flatpak"
    elif pkg_built "$pkg"; then
        echo "local"
    else
        echo "not-found"
    fi
}

# Check items in a list
chk_list() {
    local var="$1"
    local packages=("${@:2}")
    for pkg in "${packages[@]}"; do
        if dep_available "$pkg"; then
            printf -v "$var" "%s" "$pkg"
            export "$var"
            return 0
        fi
    done
    return 1
}

# Check if a PPA package is available
ppa_available() {
    local pkg=$1
    apt-cache policy "$pkg" | grep -q "Candidate:" && return 0
    return 1
}

# Detect NVIDIA GPU
nvidia_detect() {
    readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')

    if [ "$1" == "--verbose" ]; then
        for i in "${!dGPU[@]}"; do
            echo -e "\033[0;32m[gpu$i]\033[0m detected // ${dGPU[i]}"
        done
        return 0
    fi

    if [ "$1" == "--drivers" ]; then
        if grep -iq nvidia <<<"${dGPU[@]}"; then
            echo "nvidia-driver-generic"
            echo "nvidia-utils"
        fi
        return 0
    fi

    grep -iq nvidia <<<"${dGPU[@]}" && return 0 || return 1
}

# Prompt timer function
prompt_timer() {
    set +e
    unset promptIn
    local timsec=$1
    local msg=$2
    while ((timsec >= 0)); do
        echo -ne "\r :: $msg ($timsec)s : "
        read -t 1 -n 1 promptIn && break
        ((timsec--))
    done
    export promptIn
    echo ""
    set -e
}
