#!/bin/bash

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# Function securely removes the temp folder
CLEAN_EXIT() {
    TEMP_DIR=$(GET_TEMP_DIR "")
    # safety check this is wanted
    if [ "$DEBUG" = false ] && [ -d "$TEMP_DIR" ]; then
        # This block removes all temp files via shred so they are not recoverable
        find "$TEMP_DIR" -type f | while read -r file; do
            # shred options: force, remove, and zero blocks at end
            shred -f -u -z "$file"
        done
        # Removes all temp sub-dirs
        rm -rf "$TEMP_DIR"
    else
        echo "INFO" "EXITING"
    fi
}

# Clears any visual or logical gap in the UI.
# This function is typically used to reset or remove spacing elements,
# ensuring a consistent and clean user interface display.
# Usage: CLEAR_GAP
CLEAR_GAP() {
    if [ "$DEBUG" != "true" ]; then
        clear
    fi
    echo
}

# Waits for user input before continuing execution, useful for debugging purposes.
# Typically used to pause a script and allow inspection of the current state.
# Usage: Call DEBUG_WAIT at any point in your script where you want to insert a manual pause.
DEBUG_WAIT() {
    local msg="${1}"
    if [ "$DEBUG" = true ]; then
        while true; do
            echo

            debug_wait_description=($"Debug Wait")
            debug_wait_description+=("$(caller)")

            if [ -n "$msg" ]; then
                debug_wait_description+=("$msg")
            fi

            # ensure they have copied the recovery password

            if WHIPTAIL_YESNO "$ui_debug_wait_title" "debug_wait_description" "$ui_debug_wait_prompt"; then
                break #
            fi
        done
        return
    fi
}

# Prints an error message to stderr and exits the script with a non-zero status.
# Usage: ERROR_EXIT "Error message"
# Arguments:
#   $1 - The error message to display before exiting.
ERROR_EXIT() {
    echo "Script error: $(caller)"
    exit 1
}

# Function Allows user to reboot
REBOOT() {
    local reboot_description="${1:-ui_reboot_description}"
    local prompt="${2:-""}"
    local return_exit=${3:-"false"}

    no_btn="Continue"
    if [ "$return_exit" = true ]; then
        no_btn="Exit"
    fi

    if [ -z "$prompt" ]; then
        prompt=$ui_reboot_prompt
    fi

    if WHIPTAIL_YESNO "$ui_reboot_title" "$reboot_description" "$prompt" false "Reboot" "$no_btn" "true"; then
        reboot
    fi

    if [ "$return_exit" = true ]; then
        exit 1
    fi
}

# Function Allows user to reboot into UEFI config
REBOOT_TO_UEFI() {
    local msg="${1}"

    # shellcheck disable=SC2034
    reboot_uefi_message="$msg"

    export NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=white,black
        actbutton=white,red
        '

    if WHIPTAIL_YESNO "$ui_reboot_uefi_title" reboot_uefi_message "$ui_reboot_uefi_prompt" true "Reboot" "Continue"; then
        err_msg=$(systemctl reboot --firmware-setup 2>&1)
        ret="$?"
        if [ "$ret" -ne 0 ]; then
            SET_REBOOT_EFI_ERR_MSG "$err_msg"
            REBOOT "ui_reboot_uefi_error_msg" "" true
        fi
    fi

    unset NEWT_COLORS

}

# SRC_EXIT: Exits the current script or subshell.
# This function should be called to terminate the script execution gracefully.
SRC_EXIT() {

    local msg="${1}"
    local code="${2:-1}"

    if [ -n "$msg" ]; then
        # shellcheck disable=SC2034
        src_exit_msg="Caller $(caller): $msg"
        WHIPTAIL_DIALOG "$ui_src_exit_title" "src_exit_msg"
        LOG "FATAL" "Script error: Caller $(caller)  $msg"

    else
        WHIPTAIL_DIALOG "$ui_src_exit_title" "$(caller)"
        LOG "FATAL" "Script error: $(caller)"
    fi

    exit "$code"
}

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    source "../../lint/ux-helpers.lint"
    source "../../lint/ux-strings.lint"
}
