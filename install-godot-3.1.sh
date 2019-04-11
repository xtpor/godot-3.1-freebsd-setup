#!/bin/sh
# install-godot-3.1.sh
#
# Script to install godot 3.1 on FreeBSD amd64

project_dir="/tmp"
artifact="godot_server.x11.tools.64"


ensure_command_exist() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[Installer] Error: $1 is required but it is not installed on your system"
        echo "[Installer] Aborting."
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

godot_version_match() {
    vsn=`godot --version`
    case "$vsn" in
        *$1*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


# Make sure the script is running as root
user=`id -u`
if [ "$user" -ne 0 ]; then
    echo "[Installer] Permission error, please run this script as root"
    echo "[Installer] Aborting"
    exit 1
fi

ensure_command_exist git


# Check if the godot is already installed
if command_exists godot; then
    if godot_version_match "3.1.stable"; then
        echo "[Installer] Error: Godot 3.1 is already installed on your system"
        echo "[Installer] Aborting"
        exit 1
    else
        echo "[Installer] Error: Another version of godot is already installed on your system"
        echo "[Installer] Aborting"
        exit 1
    fi
fi


# Install dependencies
echo "[Installer] Installing dependencies"
pkg install -y \
    scons \
    pkgconf \
    xorg-libraries \
    libXcursor \
    libXrandr \
    libXi \
    xorgproto \
    mesa-libs \
    libGLU \
    freetype2 \
    openssl \
    yasm
if [ $? -ne 0 ]; then
    echo "[Installer] Error: Encountered error during compilation"
    echo "[Installer] Aborting"
    exit 2
fi


# Clone the repository
cd "$project_dir"
if [ ! -d "$project_dir/godot" ]; then
    echo "[Installer] Downloading the godot source code from github"
    git clone https://github.com/godotengine/godot.git
fi

cd "$project_dir/godot"
git checkout tags/3.1-stable


# Compilation
if [ -f "$project_dir/godot/bin/$artifact" ]; then
    echo "[Installer] Build artifact present, skip the build process"
else
    echo "[Installer] Compiling godot 3.1 headless"
    scons platform=server
    if [ $? -ne 0 ]; then
        echo "[Installer] Build failed, aborting"
        exit 3
    fi
fi


# Installation
from_path="$project_dir/godot/bin/$artifact"
to_path="/usr/local/bin/godot"

echo "[Installer] Installing godot"
echo "[Installer] Copying $from_path to $to_path"
cp "$from_path" "$to_path"
