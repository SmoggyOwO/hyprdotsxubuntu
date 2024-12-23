#!/usr/bin/env bash

#|---/ /+--------------------------+---/ /|#
#|--/ /-| Script to build pkgs     |--/ /-|#
#|-/ /--| Adapted for Ubuntu       |-/ /--|#
#|/ /---+--------------------------+/ /---|#

set -e  # Exit immediately if a command exits with a non-zero status

HOME_DIR=$HOME


install_dependencies() {
    # Enable multiverse and universe repositories
    sudo add-apt-repository universe
    sudo add-apt-repository multiverse

    # Update package lists
    sudo apt update

    # Install required dependencies
    sudo apt install -y \
        cargo \
        pkg-config \
        liblz4-dev \
        libcairo2-dev \
        libpango1.0-dev \
        libgtk2.0-dev \
        libxcb-xkb-dev \
        libxkbcommon-x11-dev \
        libxcb-ewmh-dev \
        libxcb-icccm4-dev \
        libxcb-cursor-dev \
        libxcb-xinerama0-dev \
        libstartup-notification0-dev \
        flex \
        bison \
        libpugixml-dev \
        qt6-base-dev \
        libdrm-dev \
        libgbm-dev \
        libsdbus-c++-dev \
        meson \
        wget \
        build-essential \
        ninja-build \
        cmake-extras \
        cmake \
        gettext \
        gettext-base \
        fontconfig \
        libfontconfig-dev \
        libffi-dev \
        libxml2-dev \
        libxkbcommon-dev \
        libxkbregistry-dev \
        libpixman-1-dev \
        libudev-dev \
        libseat-dev \
        seatd \
        libxcb-dri3-dev \
        libegl-dev \
        libgles2 \
        libegl1-mesa-dev \
        glslang-tools \
        libinput-bin \
        libinput-dev \
        libxcb-composite0-dev \
        libavutil-dev \
        libavcodec-dev \
        libavformat-dev \
        libxcb-ewmh2 \
        libxcb-ewmh-dev \
        libxcb-present-dev \
        libxcb-icccm4-dev \
        libxcb-render-util0-dev \
        libxcb-res0-dev \
        libxcb-xinput-dev \
        libtomlplusplus3 \
        libzip-dev \
        gir1.2-rsvg-2.0 \
        libtomlplusplus-dev
}

# Function to build and install a package
build_and_install() {
    cd "$HOME_DIR"
    local repo_url=$1
    local build_commands=$2

    echo "Cloning $repo_url..."
    git clone --depth 1 --no-single-branch --tags "$repo_url"

    local repo_name=$(basename "$repo_url" .git)
    cd "$repo_name"
    git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
    echo "Building $repo_name..."
    eval "$build_commands"

    echo "Finished $repo_name. Returning to home directory."
    cd "$HOME_DIR"
}

#--------------------------------------#
# Build and install packages           #
#--------------------------------------#

install_dependencies

# 1. Build swww
build_and_install "https://github.com/LGFae/swww" \
"cargo build --release && sudo cp target/release/swww /usr/local/bin/ && sudo cp target/release/swww-daemon /usr/local/bin/"

# 2. Build rofi
build_and_install "https://github.com/lbonn/rofi" \
"meson setup build && ninja -C build && ninja -C build install"

# 3. Build swaylock-effects
build_and_install "https://github.com/mortie/swaylock-effects" \
"meson build && ninja -C build && sudo ninja -C build install"

#4. Build sdbus-cpp
build_and_install "https://github.com/Kistler-Group/sdbus-cpp" \
"mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release ${OTHER_CONFIG_FLAGS} && cmake --build . && sudo cmake --build . --target install"

# 5. Build hyprutils
build_and_install "https://github.com/hyprwm/hyprutils" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && sudo cmake --install build"

# 6. Build hyprwayland-scanner
build_and_install "https://github.com/hyprwm/hyprwayland-scanner" \
"cmake -DCMAKE_INSTALL_PREFIX=/usr -B build && cmake --build build -j `nproc` && sudo cmake --install build"

# 7. Build hyprlang
build_and_install "https://github.com/hyprwm/hyprlang" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && sudo cmake --install ./build"

# 8. Build hyprland-protocols
build_and_install "https://github.com/hyprwm/hyprland-protocols" \
"meson setup build && ninja -C build && ninja -C build install"

# 9. Build hyprgraphics
build_and_install "https://github.com/hyprwm/hyprgraphics" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && sudo cmake --install build"

# 10. Build hyprcursor
build_and_install "https://github.com/hyprwm/hyprcursor" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && sudo cmake --install build"

# 11. Build aquamarine
build_and_install "https://github.com/hyprwm/aquamarine" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`"

# 12. Build hyprpicker
build_and_install "https://github.com/hyprwm/hyprpicker" \
"cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && cmake --build ./build --config Release --target hyprpicker -j\`nproc 2>/dev/null || getconf _NPROCESSORS_CONF\` && sudo cmake --install ./build"

# 13. Build ImageMagick
build_and_install "https://github.com/ImageMagick/ImageMagick" \
"./configure && make && sudo make install"

# 14. Build xdg-desktop-portal-hyprland
build_and_install "https://github.com/hyprwm/xdg-desktop-portal-hyprland" \
"cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build && cmake --build build && sudo cmake --install build"

# 15. Build hyprland
build_and_install "https://github.com/hyprwm/Hyprland" \
"make all && sudo make install"

#--------------------------------------#
# Completion message                   #
#--------------------------------------#

echo "All packages have been built and installed successfully."

