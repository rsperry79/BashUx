#!/bin/bash

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    source "../../lint/common.lint"
    source "../../lint/constants.lint"
    source "./common-strings.sh"
}

# Installs a list of packages using the apt package manager.
INSTALL_APT_PACKAGES() {
    local name=${1}
    local requirements=${2}
    local has_packages=${3}

    # shellcheck source="../templates/defaults/default-config.config"
    . "$LOCKDOWN_CONFIG_FILE"

    current=
    if [ "$has_packages" = true ]; then
        current="--defaultno"
    fi
    prompt="${ui_apt_packages_prompt} ${name}?"

    if WHIPTAIL_YESNO "$ui_apt_packages_title" "" "$prompt" "$current"; then
        INTERACTIVE_INSTALL_PACKAGES "$requirements" false
        LOCKDOWN_INSTALLED_PACKAGES=true
    else
        LOCKDOWN_INSTALLED_PACKAGES=false
    fi

    export LOCKDOWN_INSTALLED_PACKAGES
}

# Prompts the user interactively to install a list of packages.
INTERACTIVE_INSTALL_PACKAGES() {
    local requirements=${1}
    export REINSTALL_PACKAGES=${2}

    _load
    (echo "$requirements" | xargs -d '\n' --open-tty -I {} bash -c ' EXT_INSTALL_PACKAGES  "$@" ' _ {}) 2>&1 | LOG DEBUG -
}

#  Function to handle the reinstallation of the system kernel.
REINSTALL_KERNEL() {

    # shellcheck disable=SC2001
    version=$(sed 's/.*-\(.*\)-.*/\1/' <<<"${2}")
    rm -f /boot/*"$version"*
    apt install -y --reinstall "$" | LOG DEBUG -
}

#########################
# EXTERNAL COMMANDS
#########################

# Installs a predefined set of external packages required by the project.
# This function should be called during the setup or deployment process to
# ensure all necessary dependencies are available on the system.
EXT_INSTALL_PACKAGES() {
    local requirements=${1}

    export DEBIAN_FRONTEND=noninteractive

    # shellcheck source="./bash-logger.sh"
    . "$LOCKDOWN_LIBS_DIR/common/bash-logger.sh"

    if [ "$APT_UPDATED" = false ]; then
        apt update | LOG DEBUG -
        export APT_UPDATED=true
    fi

    read -ra packages <<<"$requirements"

    if [ "$REINSTALL_PACKAGES" = true ]; then
        apt reinstall -y "${packages[@]}" | LOG DEBUG -
    else
        apt install -y "${packages[@]}" | LOG DEBUG -
    fi
}

#   This function handles the installation of firmware packages required by the
#   system or application. It is intended to be used as part of the package
#   management or system setup process.
EXT_INSTALL_FIRMWARE() {
    # shellcheck source="./bash-logger.sh"
    . "$LOCKDOWN_LIBS_DIR/common/bash-logger.sh"

    fwupdmgr get-devices
    fwupdmgr refresh
    fwupdmgr get-updates
    fwupdmgr update

}

#########################
# INTERNAL COMMANDS
#########################

_load() {
    export NEEDRESTART_SUSPEND=1
    export DEBIAN_FRONTEND=noninteractive
    export APT_UPDATED=false
    export REINSTALL_PACKAGES=false
    export -f EXT_INSTALL_PACKAGES
    export -f REINSTALL_KERNEL
    export LOCKDOWN_CONFIG_FILE

}
