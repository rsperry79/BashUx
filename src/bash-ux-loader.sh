#!/bin/sh

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

BASH_UX_BASE_DIR=${1:-"$BASH_UX_BASE_DIR"}

# Ensure the script is run from the correct directory
if [ ! -d "$BASH_UX_BASE_DIR" ]; then
    echo "Error: bash-ux base directory not found. Please run this script from the correct directory. $BASH_UX_BASE_DIR"
    exit 1
fi
scripts_dir=$(realpath "$BASH_UX_BASE_DIR")
# Check for required scripts
for script in \
    $scripts_dir/config/config-helpers.sh \
    $scripts_dir/logger/bash-logger.sh \
    $scripts_dir/ux/ux-helpers.sh \
    $scripts_dir/ux/whiptail-wrapper.sh; do
    if [ ! -f "$script" ]; then
        echo "Error: '$script' not found."
        exit 1
    else
        # shellcheck disable=SC1090
        . "$script"
    fi
done
