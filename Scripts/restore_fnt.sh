#!/usr/bin/env bash

#|---/ /+------------------------------------+---/ /|#
#|--/ /-| Script to extract fonts and themes |--/ /-|#
#|-/ /--| Adapted for Ubuntu                 |-/ /--|#
#|/ /---+------------------------------------+/ /---|#

# Get the directory where the script is located
scrDir=$(dirname "$(realpath "$0")")

# Source the global functions file
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Process each line in the restore_fnt.lst file
cat "${scrDir}/restore_fnt.lst" | while read lst; do
    # Extract font name and target directory from the line
    fnt=$(echo "$lst" | awk -F '|' '{print $1}')
    tgt=$(echo "$lst" | awk -F '|' '{print $2}')
    tgt=$(eval "echo $tgt")

    # Create target directory if it doesn't exist
    if [ ! -d "${tgt}" ]; then
        if ! mkdir -p "${tgt}" 2>/dev/null; then
            echo "Creating the directory as root..."
            sudo mkdir -p "${tgt}"
        fi
        echo -e "\033[0;32m[extract]\033[0m ${tgt} directory created..."
    fi

    # Extract the font archive to the target directory
    sudo tar -xzf "${cloneDir}/Source/arcs/${fnt}.tar.gz" -C "${tgt}/"
    echo -e "\033[0;32m[extract]\033[0m ${fnt}.tar.gz --> ${tgt}..."
done

# Update font cache
echo -e "\033[0;32m[fonts]\033[0m rebuilding font cache..."
fc-cache -f
