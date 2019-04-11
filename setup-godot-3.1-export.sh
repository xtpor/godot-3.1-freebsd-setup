#!/bin/sh
# Setup the export environment for Godot 3.1 stable for FreeBSD
# Usage: ./setup-godot-3.1-export.sh

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_command_exist() {
    if ! command_exists "$1"; then
        echo "[Installer] Error: $1 is required but it is not installed on your system"
        echo "[Installer] Aborting."
        exit 1
    fi
}

setup_export_template() {
    tmp_directory="/tmp/setup-godot-3.1-export"
    filename="Godot_v3.1-stable_export_templates.tpz"
    template_url="https://downloads.tuxfamily.org/godotengine/3.1/Godot_v3.1-stable_export_templates.tpz"


    ensure_command_exist wget
    mkdir -p "$tmp_directory"


    cd "$tmp_directory"

    if [ ! -f "$filename" ]; then
        echo "[Installer] Downloading export template"
        wget "$template_url"
    fi

    if [ ! -d "templates" ]; then
        echo "[Installer] Unpacking export template"
        unzip "$filename"
    fi

    if [ ! -d ~/.local/share/godot/templates/3.1.stable ]; then
        echo "[Installer] Installing export template"
        mkdir -p ~/.local/share/godot/templates
        cp -r "$tmp_directory/templates" ~/.local/share/godot/templates/3.1.stable
    fi
}


setup_android_env() {
    # Install all the dependencies for build for android
    if ! command_exists adb; then
        echo "[Installer] Installing adb"
        sudo pkg install -y android-tools-adb >/dev/null
    fi

    if ! command_exists jarsigner; then
        echo "[Installer] Installing openjdk8 (for jarsigner)"
        sudo pkg install -y openjdk8  >/dev/null
    fi

    # Android specific settings
    adb_location=`which adb`
    jarsigner_location=`which jarsigner`
    keystore_location=~/.android/debug.keystore

    ## Generate Andoird debug keystore
    if [ ! -f "$keystore_location" ]; then
        echo "[Installer] Creating debug keystore"
        keystore_dir=`dirname $keystore_location`

        mkdir -p "$keystore_dir"
        cd "$keystore_dir"
        keytool -genkey -v -keystore debug.keystore \
            -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown" \
            -alias androiddebugkey \
            -storepass android \
            -keypass android \
            -keyalg RSA \
            -validity 14000
    fi

    if [ ! -f ~/.config/godot/editor_settings-3.tres ]; then
        # Force godot to generate editor config
        echo "[Installer] Generating editor settings"
        godot &
        sleep 2
        kill $!

        # Set the android specfic config in ~/.config/editor_settings-3.tres
        echo "[Installer] Setting android related settings"

        echo "export/android/adb = \"$adb_location\"" >> ~/.config/godot/editor_settings-3.tres
        echo "export/android/jarsigner = \"$jarsigner_location\"" >> ~/.config/godot/editor_settings-3.tres
        echo "export/android/debug_keystore = \"$keystore_location\"" >> ~/.config/godot/editor_settings-3.tres
    fi
}


setup_export_template
setup_android_env
echo "[Installer] Done."
