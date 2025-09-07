#!/bin/bash

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

ARGS=$(getopt -o m:c:d:l: --long mode:,config:,debug:,libs: -- "$@") || exit 1
eval set -- "$ARGS"

LOCKDOWN_DEBUG=${LOCKDOWN_DEBUG:-false}
LOCKDOWN_MODE=${LOCKDOWN_MODE:-"menu"}
LOCKDOWN_CONFIG_FILE=${LOCKDOWN_CONFIG_FILE:-"/etc/lockdown.config"}
LOCKDOWN_LIBS_DIR=${LOCKDOWN_LIBS_DIR:-"/usr/lib/lockdown"}
LOCKDOWN_CALLER=${BASH_SOURCE[1]}

while true; do
    cleaned_switch=${1//\'/} #
    case "$cleaned_switch" in
    -m | --mode)
        cleaned_string=${2//\'/}
        trimmed="${cleaned_string#"${cleaned_string%%[![:space:]]*}"}" # Remove leading
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"               # Remove trailing # remove single quotes, as bash inserts this in a script to script.
        LOCKDOWN_MODE="$trimmed"
        shift 2
        ;;
    -c | --config)
        cleaned_string=${2//\'/}
        trimmed="${cleaned_string#"${cleaned_string%%[![:space:]]*}"}" # remove single quotes, as bash inserts this in a script to script.
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"               # Remove trailing
        if [ -e "$trimmed" ]; then
            LOCKDOWN_CONFIG_FILE="$trimmed"
            shift 2
        fi
        ;;
    -l | --libs)
        cleaned_string=${2//\'/}                                       # remove single quotes, as bash inserts this in a script to script.
        trimmed="${cleaned_string#"${cleaned_string%%[![:space:]]*}"}" # remove single quotes, as bash inserts this in a script to script.
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"               # Remove trailing
        if [ -d "$trimmed" ]; then
            LOCKDOWN_LIBS_DIR="$trimmed"
            shift 2
        else
            echo "Invalid path. $2"
            exit 1
        fi
        ;;
    -d | --debug)
        cleaned_string=${2//\'/}                                       # remove single quotes, as bash inserts this in a script to script.
        trimmed="${cleaned_string#"${cleaned_string%%[![:space:]]*}"}" # remove single quotes, as bash inserts this in a script to script.
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"               # Remove trailing
        if [ "$trimmed" = true ] || [ "$trimmed" = false ]; then
            LOCKDOWN_DEBUG="$trimmed"
            shift 2
        else
            echo "Debug must be  true or false. $2"
            exit 1
        fi
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Not implemented: $1"
        exit 1
        ;;
    esac
done

# shellcheck source="./common.sh"
source "$LOCKDOWN_LIBS_DIR/common.sh" "$LOCKDOWN_CONFIG_FILE" "$LOCKDOWN_LIBS_DIR" #Loads common scripts and configs

export LOCKDOWN_MODE
export LOCKDOWN_DEBUG
export LOCKDOWN_CONFIG_FILE
export LOCKDOWN_LIBS_DIR

# TODO make this useful
app_name=
if echo "$LOCKDOWN_CALLER" | grep -q "secureboot"; then
    app_name="LockDown-SecureBoot"
elif echo "$LOCKDOWN_CALLER" | grep -q "grub"; then
    app_name="LockDown-Grub"
elif echo "$LOCKDOWN_CALLER" | grep -q "luks"; then
    app_name="LockDown-LUKS"
elif echo "$LOCKDOWN_CALLER" | grep -q "entry"; then
    app_name="LockDown"
fi
