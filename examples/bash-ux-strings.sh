#!/bin/bash

# shellcheck disable=SC2034

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# DEBUG_WAIT
ui_debug_wait_title=$"Debug Wait"
debug_wait_description=($"Debug Wait")
ui_debug_wait_prompt=$"Ready to continue?"

# REBOOT
ui_reboot_title=$"Reboot?"
ui_reboot_description=($"To apply changes, you must reboot the system")
ui_reboot_prompt=$"Do you want to reboot or continue?"

# REBOOT_TO_UEFI
ui_reboot_uefi_title=$"Reboot to UEFI?"

ui_reboot_uefi_message=()

SET_REBOOT_EFI_ERR_MSG() {
    local msg=${1}
    ui_reboot_uefi_error_msg=("$msg")
    ui_reboot_uefi_error_msg+=($"You will need to manually enter the BIOS after reboot.")

}

ui_reboot_uefi_prompt=$"Do you want to reboot into the BIOS to clear SecureBoot config or continue running this script?"

# SRC_EXIT
ui_src_exit_title=$"Script error"
