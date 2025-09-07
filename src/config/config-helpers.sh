#!/bin/bash

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# Sets a configuration value in the configuration file.
SET_CONFIG() {
    local setting=${1}
    local value=${2}

    # Config file loaded from global vars
    if ! sed -i "/${setting}=/c ${setting}=\"${value}\"" "$BASH_UX_CONFIG_FILE"; then
        WHIPTAIL_DIALOG "$ui_set_config_title" "ui_set_ld_config_write"
        exit 1
    fi

    if ! export "${setting}"="$value"; then
        WHIPTAIL_DIALOG "$ui_set_config_title" "ui_set_ld_config_export"
        exit 1
    else
        if [ "$DEBUG" = true ]; then
            LOG INFO "SET $setting to $value "
        fi
    fi
    return 0
}

# Retrieves configuration files or settings.
GET_CONFIG() {
    local cfg=${1:-$BASH_UX_CONFIG_FILE}
    local default_cfg=${2:-$BASH_UX_DEFAULT_CONFIG_FILE}

    if [ -z "$cfg" ] || [ -z "$default_cfg" ]; then
        WHIPTAIL_DIALOG "$ui_get_config_title" "ui_get_ld_config_message"
        exit 1
    fi

    # Ensure the script is run from the correct directory
    if [ ! -e "$cfg" ]; then

        if ! cp "$default_cfg" "$cfg"; then
            WHIPTAIL_DIALOG "$ui_get_config_title" "ui_get_config_failed_to_copy"
            exit 1
        fi
    fi

    # Load the configuration file
    # shellcheck source="../../lint/config/default_config.sh"
    if ! source "$cfg"; then
        echo "Error: Failed to load configuration from '$cfg'."
        exit 1
    fi

    export BASH_UX_CONFIG_FILE=$cfg
}

SET_CONF_BY_CHECKBOX() {
    local ui_title=${1}
    local ui_setting_description=${2}
    local ui_prompt=${3}
    local options=${4}
    local order=${5}
    local ui_setting=${6}

    selection=$(
        WHIPTAIL_CHECK_LIST "$ui_title" "$ui_setting_description" "$ui_prompt" "$options" "$order" "${!ui_setting}"
    )
    ret=$?
    if [ "$ret" -ne 0 ]; then
        LOG "FATAL" "Failed to set $ui_setting with ERR: $ret"
        return 1
    else
        SET_CONFIG "$ui_setting" "$selection"
    fi
}

SET_CONF_BY_INPUTBOX() {
    local ui_title=${1}
    local ui_setting_description=${2}
    local ui_prompt=${3}
    local ui_setting=${4}

    input_selection=$(WHIPTAIL_INPUTBOX "$ui_title" "$ui_setting_description" "$ui_prompt" "${!ui_setting}")
    ret=$?
    if [ "$ret" -ne 0 ]; then
        LOG "FATAL" "Failed to set $ui_setting with ERR: $ret"
        return 1
    else
        SET_CONFIG "$ui_setting" "$input_selection"
    fi
}

SET_CONF_BY_RADIO() {
    local ui_title=${1}
    local ui_assoc_arr_options=${2}
    local order=${3}
    local ui_setting=${4}
    local ui_recommended=${5}
    local ui_setting_description=${6}
    local ui_prompt=${7}

    selection=$(
        WHIPTAIL_RADIO "$ui_title" "$ui_assoc_arr_options" "$order" "$ui_setting" "$ui_recommended" "$ui_setting_description" "$ui_prompt"
    )
    ret=$?
    if [ "$ret" -ne 0 ]; then
        LOG "FATAL" "Failed to set $ui_setting with ERR: $ret"
        return 1
    else
        lower_sel="${selection,,}"
        SET_CONFIG "$ui_setting" "$lower_sel"
    fi
}

SET_CONF_BY_YESNO() {
    local ui_title=${1}
    local ui_messages=${2}
    local ui_prompt=${3}
    local ui_setting=${4}
    local ui_yes_button_txt=${5:-"Yes"}
    local ui_no_button_txt=${6:-"No"}
    local ui_alert=${7:-"false"}

    current=false
    if [ "${!ui_setting}" = true ]; then
        current=true
    fi

    if WHIPTAIL_YESNO "$ui_title" "$ui_messages" "$ui_prompt" "$current" "$ui_yes_button_txt" "$ui_no_button_txt" "$ui_alert"; then
        SET_CONFIG "$ui_setting" "true"
        return 0
    else
        SET_CONFIG "$ui_setting" "false"
        return 1
    fi
}

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    source "../../lint/base.lint"
    source "../../lint/config/config-helpers.lint"
    source "../../lint/config/config-strings.lint"
}
