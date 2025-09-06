#!/bin/bash

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

ui_back_title=

WHIPTAIL_SET_APP_NAME() {
    declare -g ui_back_title
    ui_back_title=$(_set_backtitle "${1:-""}")
}

WHIPTAIL_CHECK_LIST() {
    local ui_title=${1}
    local -n ui_setting_description=${2}
    local ui_prompt=${3}
    local -n ui_options=${4}
    local -n ui_order=${5}
    local current_selection=${6}

    eval "$(resize)"
    cb_lines=0
    desc_lines=0
    col_buffer=5
    columns=78
    whiptail_args=()
    ui_display_message=""

    for line in "${ui_setting_description[@]}"; do
        ui_display_message+="$line\n"

        str_length=${#line}
        length=$((str_length + col_buffer))
        if [ "$length" -gt "$columns" ]; then
            columns=$length
        fi
        desc_lines=$((desc_lines + 1))
    done

    ui_display_message+="\n$ui_prompt"
    desc_lines=$((desc_lines + 2)) #

    # Get Current Selection
    IFS=',' read -r -a current_options <<<"$current_selection"

    for key in "${ui_order[@]}"; do
        opt_set=OFF

        # Check if the current option is in the current selection
        for item in "${current_options[@]}"; do
            if [[ "$item" == "$key" ]]; then
                opt_set=ON
                break
            fi
        done

        # Prepare the display string
        desc_buffer="     "
        whiptail_args+=("$key")
        whiptail_args+=("${ui_options[$key]}$desc_buffer")
        whiptail_args+=("$opt_set")
        cb_lines=$((cb_lines + 1))
    done

    # shellcheck disable=SC2004
    lines=$(($cb_lines - desc_lines + 1)) # +1 for the prompt line

    # shellcheck disable=SC2004
    selection=$(whiptail --title "$ui_title" --backtitle "$ui_back_title" --checklist "$ui_display_message" "$LINES" "$columns" "$lines" "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
    ret=$?
    if [ "$ret" -ne 0 ]; then
        return 1
    else
        # Convert selection to array
        CSV_OUTPUT=$(echo "$selection" | tr -d '"' | tr ' ' ',')
        echo "$CSV_OUTPUT" # Output: 1,2,3,4,5
    fi
}

WHIPTAIL_DIALOG() {
    local title=${1}
    local -n message=${2}

    # ui_back_title=$(_set_backtitle "$ui_app_name")

    eval "$(resize)"

    lines=8
    col_buffer=5
    columns=78
    ui_display_message=""

    for line in "${message[@]}"; do
        ui_display_message+="$line\n"
        lines=$((lines + 1))

        str_length=${#line}
        length=$((str_length + col_buffer))
        if [ "$length" -gt "$columns" ]; then
            columns=$length
        fi
    done

    # shellcheck disable=SC2004
    whiptail --title "$title" --backtitle "$ui_back_title" --msgbox "$ui_display_message" "$lines" "$columns" 3>&1 1>&2 2>&3
    ret=$?

    if [ "$ret" -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

WHIPTAIL_INPUTBOX() {
    local ui_title=${1}
    local -n ui_messages=${2}
    local ui_prompt=${3}
    local ui_placeholder=${4}

    # ui_back_title=$(_set_backtitle "$ui_app_name")

    lines=6
    col_buffer=5
    columns=78
    ui_display_message=""

    for line in "${ui_messages[@]}"; do
        ui_display_message+="$line\n"
        lines=$((lines + 1))

        str_length=${#line}
        length=$((str_length + col_buffer))
        if [ "$length" -gt "$columns" ]; then
            columns=$length
        fi
    done

    ui_display_message+="\n$ui_prompt"

    if [ "$lines" -lt 8 ]; then
        lines=8
    fi

    eval "$(resize)"

    whiptail --title "$ui_title" --backtitle "$ui_back_title" --inputbox "$ui_display_message" $(($LINES - 8)) "$columns" "$ui_placeholder" 3>&1 1>&2 2>&3
    ret=$?
    if [ "$ret" -ne 0 ]; then
        return "$ret"
    fi
}

WHIPTAIL_MENU() {
    local title=${1}
    local -n menu_items=${2}
    local -n order=${3}
    local prompt=${4:-"Choose an option"}
    local ui_ok_button_txt=${5:-"$ui_menu_yes_text"}
    local ui_cxl_button_txt=${6:-"$ui_menu_no_text"}

    eval "$(resize)"
    col_buffer=5
    columns=78
    lines=6

    for ((i = ${#order[@]} - 1; i >= 0; i--)); do
        reversed_array+=("${order[i]}")
    done

    txt_buffer="     "
    ordered=()
    for key in "${reversed_array[@]}"; do
        ordered=("$key$txt_buffer" "${menu_items[$key]}$txt_buffer" "${ordered[@]}")
        lines=$(($lines + 1)) #

        str_length=${#ordered}
        length=$((str_length + col_buffer))
        if [ "$length" -gt "$columns" ]; then
            columns=$length
        fi
    done

    # IO IS REVERSED
    # shellcheck disable=SC20045
    sel=$(whiptail --title "$title" --backtitle "$ui_back_title" --menu "$prompt" --ok-button "$ui_ok_button_txt" --cancel-button "$ui_cxl_button_txt" "$LINES" "$columns" "$lines" "${ordered[@]}" 3>&1 1>&2 2>&3)
    ret=$?

    if [ "$ret" -ne 0 ]; then
        return 1
    else
        sel="${sel#"${sel%%[![:space:]]*}"}" # remove leading whitespace characters
        sel="${sel%"${sel##*[![:space:]]}"}" # remove trailing whitespace characters
        echo "$sel"
        return 0
    fi
}

WHIPTAIL_PASSWORD() {
    local ui_title=${1}
    local ui_prompt=${2}
    local ui_error_message=${3:-""}

    if [ -n "$ui_error_message" ]; then
        ui_prompt="$ui_error_message\n\n$ui_prompt"
    fi

    col_buffer=5
    str_length=${#ui_prompt}
    line_length=$(($str_length + $col_buffer)) #

    user_password=$(whiptail --title "$ui_title" --backtitle "$ui_back_title" --passwordbox "$ui_prompt" 10 "$line_length" 3>&1 1>&2 2>&3)
    ret=$?
    if [ "$ret" -ne 0 ]; then
        return 1
    else
        echo "$user_password"
    fi
}

WHIPTAIL_RADIO() {
    local ui_title=${1}
    local -n ui_assoc_arr_options=${2}
    local -n order=${3}
    local ui_setting=${4}
    local ui_recommended=${5}
    local -n ui_setting_description=${6}
    local ui_prompt=${7}

    # ui_back_title=$(_set_backtitle "$ui_app_name")

    eval "$(resize)"

    desc_lines=0
    rb_lines=0
    lines=6
    col_buffer=5
    columns=78
    ui_display_message=""

    for line in "${ui_setting_description[@]}"; do
        ui_display_message+="$line\n"
        desc_lines=$((desc_lines + 1))

        str_length=${#line}
        length=$((str_length + col_buffer))
        if [ "$length" -gt "$columns" ]; then
            columns=$length
        fi
    done

    ui_display_message+="\n$ui_prompt"
    desc_lines=$((desc_lines + 2)) #

    whiptail_args=()

    for key in "${order[@]}"; do
        active="OFF"
        if [ "$key" = "${!ui_setting}" ]; then
            active="ON"
        fi

        desc=${ui_assoc_arr_options[${key}]}

        if [ "$key" = "$ui_recommended" ]; then

            desc="RECOMMENDED - ${ui_assoc_arr_options[${key}]}"
        fi

        desc_buffer="     "
        upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
        whiptail_args+=("$upper_key")
        whiptail_args+=("$desc$desc_buffer")
        whiptail_args+=("$active")
        rb_lines=$((rb_lines + 1))

    done
    lines=$(($LINES - desc_lines)) # +1 f
    #lines=$(($rb_lines - desc_lines)) # +1 f

    selection=$(
        whiptail --title "$ui_title" --backtitle "$ui_back_title" --radiolist "$ui_display_message" "$LINES" "$columns" "8" "${whiptail_args[@]}" 3>&1 1>&2 2>&3
    )

    ret=$?
    if [ "$ret" -ne 0 ]; then

        return "$ret"
    else
        lower_sel="${selection,,}"
        echo "$lower_sel"
    fi
}

BASH_UX_PROGRESS_UI_TITLE=

BASH_UX_PROGRESS_FIFO_DIR=
BASH_UX_PROGRESS_TOTAL=
BASH_UX_PROGRESS_POINTS=
BASH_UX_PROGRESS_LINES=6
BASH_UX_PROGRESS_COLUMNS=50

WHIPTAIL_PROGRESS() {
    BASH_UX_PROGRESS_UI_TITLE=${1}
    local progress_description=${2}

    BASH_UX_PROGRESS_TOTAL=${3}
    if [ -z "$BASH_UX_PROGRESS_TOTAL" ]; then
        echo "BASH_UX_PROGRESS_TOTAL is null"
        exit 1
    fi

    unset NEWT_COLORS

    BASH_UX_PROGRESS_FIFO_DIR=$(mktemp -d)

    # ui_back_title=$(_set_backtitle "$ui_app_name")

    # Create the FIFO for communicating with the whiptail gauge
    mkfifo "$BASH_UX_PROGRESS_FIFO_DIR/fifo"

    # Start up the whiptail gauge and associate FD 3 with its status

    whiptail --title "$BASH_UX_PROGRESS_UI_TITLE" --backtitle "$ui_back_title" --gauge "$progress_description" "$BASH_UX_PROGRESS_LINES" "$BASH_UX_PROGRESS_COLUMNS" 0 <"$BASH_UX_PROGRESS_FIFO_DIR/fifo" 3>&1 1>&2 2>&3 &
    exec 4<>"$BASH_UX_PROGRESS_FIFO_DIR/fifo"

    if [ -z "$BASH_UX_PROGRESS_POINTS" ]; then
        BASH_UX_PROGRESS_POINTS=0
    fi
}

WHIPTAIL_PROGRESS_RESTORE() {
    progress_description=${1:-""}

    unset NEWT_COLORS

    percent=$((BASH_UX_PROGRESS_POINTS * 100 / BASH_UX_PROGRESS_TOTAL))

    whiptail --title "$BASH_UX_PROGRESS_UI_TITLE" --backtitle "$ui_back_title" --gauge "$progress_description" "$BASH_UX_PROGRESS_LINES" "$BASH_UX_PROGRESS_COLUMNS" "$percent" <"$BASH_UX_PROGRESS_FIFO_DIR/fifo" 3>&1 1>&2 2>&3 &
    exec 4<>"$BASH_UX_PROGRESS_FIFO_DIR/fifo"

    if [ -n "$progress_description" ]; then
        WHIPTAIL_PROGRESS_UPDATE "$progress_description"
    fi

}

WHIPTAIL_PROGRESS_UPDATE() {
    progress_description="$1"
    count=${2:-1}

    WHIPTAIL_PROGRESS_SKIP "$count"
    percent=$((BASH_UX_PROGRESS_POINTS * 100 / BASH_UX_PROGRESS_TOTAL))
    _update_progress "$progress_description" "$percent" "$BASH_UX_PROGRESS_COLUMNS"

    LOG "INFO" "$progress_description" # write to log
}

WHIPTAIL_PROGRESS_SKIP() {
    count=${1:-1}
    BASH_UX_PROGRESS_POINTS=$((BASH_UX_PROGRESS_POINTS + $count))
}

BASH_UX_SUB_PROGRESS_UI_TITLE=
BASH_UX_SUB_PROGRESS_TOTAL=
BASH_UX_SUB_PROGRESS_POINTS=

WHIPTAIL_SUB_PROGRESS() {
    BASH_UX_SUB_PROGRESS_UI_TITLE=${1}
    progress_description=${2}

    BASH_UX_SUB_PROGRESS_TOTAL=${3}
    if [ -z "$BASH_UX_SUB_PROGRESS_TOTAL" ]; then
        echo "BASH_UX_SUB_PROGRESS_TOTAL is null"
        exit 1
    fi

    if [ -z "$BASH_UX_SUB_PROGRESS_POINTS" ]; then
        BASH_UX_SUB_PROGRESS_POINTS=0
    fi

    LOG DEBUG "$progress_description"

    export NEWT_COLORS=$SUBSHELL_THEME

    whiptail --title "$BASH_UX_SUB_PROGRESS_UI_TITLE" --backtitle "$ui_back_title" --gauge "$progress_description" 6 50 0 <"$BASH_UX_PROGRESS_FIFO_DIR/fifo" 3>&1 1>&2 2>&3 &
    exec 4<>"$BASH_UX_PROGRESS_FIFO_DIR/fifo"

}

# Subshell does not update so we restore every time instead.
WHIPTAIL_SUB_PROGRESS_RESTORE() {
    progress_description=${1}
    points=${2}

    percent=$((points * 100 / BASH_UX_SUB_PROGRESS_TOTAL))

    msg_length=${#progress_description}
    needed_space=$((msg_length + 5))
    if [ "$needed_space" -lt 50 ]; then
        needed_space=50
    fi

    whiptail --title "$BASH_UX_SUB_PROGRESS_UI_TITLE" --backtitle "$ui_back_title" --gauge "$progress_description" "$BASH_UX_PROGRESS_LINES" "$needed_space" "$percent" <"$BASH_UX_PROGRESS_FIFO_DIR/fifo" 3>&1 1>&2 2>&3 &
    exec 4<>"$BASH_UX_PROGRESS_FIFO_DIR/fifo"

    if [ -n "$progress_description" ]; then
        WHIPTAIL_SUB_PROGRESS_UPDATE "$progress_description"
    fi
}

WHIPTAIL_YESNO() {
    # shellcheck disable=SC2034
    blank_msg=()

    local ui_title=${1}
    local -n ui_messages=${2:-"blank_msg"}
    local ui_prompt=${3}
    local ui_set_default_yes=${4-:"true"}
    local ui_yes_button_txt=${5:-"Yes"}
    local ui_no_button_txt=${6:-"No"}
    local ui_alert=${7:-"false"}

    #  # ui_back_title=$(_set_backtitle "$ui_app_name")

    ui_default_no=""
    if [ "$ui_set_default_yes" = false ]; then
        ui_default_no="--defaultno"
    fi

    lines=6
    col_buffer=5
    columns=78
    ui_display_message=""

    for line in "${ui_messages[@]}"; do
        if [ -n "$line" ]; then
            ui_display_message+="$line\n"
            lines=$((lines + 1))

            str_length=${#line}
            length=$((str_length + col_buffer))
            if [ "$length" -gt "$columns" ]; then
                columns=$length
            fi
        fi
    done

    if [ "$lines" -gt 6 ]; then
        ui_display_message+="\n"
        lines=$((lines + 1))
    fi

    ui_display_message+="$ui_prompt"
    lines=$((lines + 1))

    if [ "$ui_alert" = true ]; then
        export NEWT_COLORS=$ALERT_THEME
    fi
    eval "$(resize)"

    if whiptail --backtitle "$ui_back_title" --title "$ui_title" --yesno "$ui_display_message" --yes-button "$ui_yes_button_txt" --no-button "$ui_no_button_txt" "$ui_default_no" "$lines" "$columns" 3>&1 1>&2 2>&3; then
        unset NEWT_COLORS
        return 0
    else
        unset NEWT_COLORS
        return 1
    fi

}

#########################
# INTERNAL COMMANDS
#########################

_set_backtitle() {
    local ui_app_name=${1:-""}
    if [ -n "$ui_app_name" ]; then
        echo "LockDown-$ui_app_name"
    else
        echo "LockDown"
    fi
}

_update_progress() {
    local progress_description=${1}
    local percent=${2}
    local wanted_length=${3}

    msg_length=${#progress_description}
    needed_space=$((wanted_length - msg_length))
    padded_msg=$progress_description$(printf '%*s' "$needed_space" "")
    msg=$(printf "XXX\n%d\n%s\nXXX\n" "$percent" "$padded_msg")
    echo "$msg" >&4

    # echo "XXX" >&4                   # write to FIFO
    # printf "%d\n" "$percent" >&4     # write to FIFO
    # printf " %s\n" "$padded_msg" >&4 # write to FIFO
    # echo "XXX" >&4                   # write to FIFO
}

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    source "../../lint/whiptail-theme.lint"
}
