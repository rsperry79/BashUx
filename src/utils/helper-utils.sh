#!/bin/sh

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# Removes shellcheck comments from a file.
CLEAN_SHELLCHECK() {
    to_clean="${1}"

    if [ -e "$to_clean" ]; then
        sed -i '/^# shellcheck/d' "$to_clean"
    else
        echo "Warning: $to_clean not found for cleaning."
    fi
}

# Securely deletes a file by overwriting its contents before removal.
DO_SHRED() {
    location=${1}

    if [ -d "$location" ]; then # if dir
        shred -f -u -z "$location"/*
        rm -rf "$location"
    else # if file
        # shred options: force, remove, and zero blocks at end
        shred -f -u -z "$location"
    fi

}

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    . "../../lint/helpers/helper-utils.lint"
}
