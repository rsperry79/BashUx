#!/bin/sh

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# Vars
# LOGGER_NAME=${LOGGER_NAME:-""}
# LOGGER_DATE_FORMAT=${LOGGER_DATE_FORMAT:-+%F %T}

# # Log levels
# LOGGER_MIN_LEVEL=${LOGGER_MIN_LEVEL:-3}
# LOGGER_CONSOLE_LEVEL=${LOGGER_MIN_LEVEL}
# LOGGER_FILE_LEVEL=${LOGGER_MIN_LEVEL}
# LOGGER_JSON_LEVEL=${LOGGER_MIN_LEVEL}
# LOGGER_SYSLOG_LEVEL=${LOGGER_MIN_LEVEL}

# # Enabled Loggers
# # LOGGER_ENABLE_[opt] uses c bool values. 0 for true, 1 for false
# LOGGER_ENABLE_FILE=
# LOGGER_ENABLE_SYSLOG=
# LOGGER_ENABLE_JSON=
# LOGGER_ENABLE_CONSOLE=

# # File Paths
# LOGGER_LOG_PATH=
# LOGGER_LOG_FILE_PATH=
# LOGGER_LOG_JSON_PATH=

LOGGER_IS_INIT() {
    # C style bool

    if [ -z "${LOGGER_NAME+x}" ]; then
        return 1
    fi
    if [ -n "$LOGGER_NAME" ]; then
        # True
        return 0
    else
        # False
        return 1
    fi

}

LOGGER_SETUP() {
    level="${1:-3}"

    _setup_colors
    _setup_logger_levels

    if ! LOGGER_IS_INIT; then
        LOGGER_NAME=${2:-"Bash-Logger"}
        _setup_log_path "${3:-"/var/log"}"
        LOGGER_MIN_LEVEL=$(_get_log_level "$(printf "%s" "$level" | tr '[:lower:]' '[:upper:]')")

        export LOGGER_MIN_LEVEL
        export LOGGER_NAME
        export LOGGER_DATE_FORMAT="${4:-+%F %T}"
        export LOGGER_ENABLE_FILE=1
        export LOGGER_ENABLE_JSON=1
        export LOGGER_ENABLE_SYSLOG=1
        export LOGGER_ENABLE_CONSOLE=1
    fi

}

LOGGER_ENABLE_CONSOLE() {
    level="${1:-LOGGER_MIN_LEVEL}"
    LOGGER_CONSOLE_LEVEL=$(_get_log_level "$(printf "%s" "$level" | tr '[:lower:]' '[:upper:]')")
    export LOGGER_CONSOLE_LEVEL
    export LOGGER_ENABLE_CONSOLE=0
}

LOGGER_ENABLE_FILE() {
    level="${1:-$LOGGER_MIN_LEVEL}"
    LOGGER_FILE_LEVEL=$(_get_log_level "$(printf "%s" "$level" | tr '[:lower:]' '[:upper:]')")
    export LOGGER_FILE_LEVEL

    file_name=${2:-$(echo "$LOGGER_NAME" | sed 's/ /_/g')} # replace spaces with underscore
    cur_date_time=$(/bin/date +"%F-%H-%M")
    LOGGER_LOG_FILE_PATH="$LOGGER_LOG_PATH"/$file_name.$cur_date_time.log
    export LOGGER_LOG_FILE_PATH

    export LOGGER_ENABLE_FILE=0
}

LOGGER_ENABLE_JSON() {
    level="${1:-LOGGER_MIN_LEVEL}"
    LOGGER_JSON_LEVEL=$(_get_log_level "$(printf "%s" "$level" | tr '[:lower:]' '[:upper:]')")
    export LOGGER_JSON_LEVEL

    file_name=${2:-$(echo "$LOGGER_NAME" | sed 's/ /_/g')} # replace spaces with underscore
    cur_date_time=$(/bin/date +"%F-%H-%M")
    export LOGGER_LOG_JSON_PATH="$LOGGER_LOG_PATH"/"$file_name"."$cur_date_time".json.log

    export LOGGER_ENABLE_JSON=0
}

LOGGER_ENABLE_SYSLOG() {
    level="${1:-$LOGGER_MIN_LEVEL}"

    LOGGER_SYSLOG_LEVEL=$(_get_log_level "$(printf "%s" "$level" | tr '[:lower:]' '[:upper:]')")
    export LOGGER_SYSLOG_LEVEL
    LOGGER_SYSLOG_TAG_DEFAULT=$(echo "$LOGGER_NAME" | sed 's/ /_/g')
    export LOGGER_SYSLOG_TAG="${2:-$LOGGER_SYSLOG_TAG_DEFAULT}"
    export LOGGER_SYSLOG_FACILITY="${3:-0}"
    export LOGGER_ENABLE_SYSLOG=0
}

LOG() {
    # If not Init log to console and warn.
    if ! LOGGER_IS_INIT; then
        shift 1
        msg="${*}"
        # Check if intent is to pipe stdin
        if [ "$msg" = - ]; then
            msg=$(cat /dev/stdin)
        fi
        if [ -n "$msg" ]; then
            printf "\033[0;   Bash-Logger not initialized\033[0m "
            echo "$msg"
        fi

        return
    fi

    if [ -z "$LOGGER_LEVEL_DEBUG" ]; then
        _setup_logger_levels
    fi

    # Get log level and throw if not sent
    level="$(printf "%s" "$1" | tr '[:lower:]' '[:upper:]')"
    if [ -z "$level" ]; then
        _logger_fatal "$msg"
    fi
    # Convert to int if needed
    severity=$(_get_log_level "$level")

    # Move to message
    shift 1
    msg="${*}"
    # Check if intent is to pipe stdin
    if [ "$msg" = - ]; then
        msg=$(cat /dev/stdin)
    fi

    # If the message is null return. This is common when piping stdin.
    if [ -z "$msg" ]; then
        return
    fi

    # CONSOLE Logger. Since this is the only place where sensitive can be logged, we check separately
    if [ "$LOGGER_ENABLE_CONSOLE" -eq 0 ] && [ "$severity" -le "${LOGGER_CONSOLE_LEVEL}" ]; then
        _log_console "$level" "$msg"
    fi
    # Check if other loggers are enabled and log
    if [ "$severity" -ne "$(_get_log_level "SENSITIVE")" ]; then # We should never log sensitive info to logs
        # SYSLOG
        if [ "${LOGGER_ENABLE_SYSLOG}" -eq 0 ] && [ "$severity" -le "${LOGGER_SYSLOG_LEVEL}" ]; then
            _log_syslog "$level" "$msg"
        fi

        # FILE
        if [ "${LOGGER_ENABLE_FILE}" -eq 0 ] && [ "$severity" -le "${LOGGER_FILE_LEVEL}" ]; then
            _log_file "$level" "$msg"
        fi

        # JSON
        if [ "${LOGGER_ENABLE_JSON=}" -eq 0 ] && [ "$severity" -le "${LOGGER_JSON_LEVEL}" ]; then
            _log_json "$level" "$msg"
        fi
    fi

}

#########################
# INTERNAL COMMANDS
#########################

_log_console() {
    level="${1}"
    msg="${2}"

    severity=$(_get_log_level "$level")

    if [ "$severity" -le "${LOGGER_CONSOLE_LEVEL}" ]; then
        date_time="$(date "${LOGGER_DATE_FORMAT}")"

        color="$(_get_color "$level")"
        # shellcheck disable=SC3037 # SC3037 is not posix compliant, but we want to use it
        echo -e "${color} ${date_time} [${level}] ${msg} ${COLOR_DEFAULT}"
    fi
}

_log_file() {
    level="${1}"
    msg="${2}"

    date_time="$(date "${LOGGER_DATE_FORMAT}")"
    file_line="${date_time} [${level}] ${msg}"

    printf "%s\n" "${file_line}" >>"${LOGGER_LOG_FILE_PATH}" ||
        _logger_fatal "\"${file_line}\" >> \"${LOGGER_LOG_FILE_PATH}\""
}

_log_json() {
    level="${1}"
    msg="${2}"

    json_line="$(printf '{"timestamp":"%s","level":"%s","message":"%s"}' "$(date "+%s")" "${level}" "${msg}")"
    printf "%s\n" "${json_line}" >>"${LOGGER_LOG_JSON_PATH}" ||
        _logger_fatal "echo -e \"${LOGGER_LOG_JSON_PATH}\" >> \"${LOGGER_LOG_JSON_PATH}\""
}

_log_syslog() {
    level="${1}"
    msg="${2}"

    severity="$(_get_log_level "$level")"
    syslog_line="${level}: ${msg}"
    pid="${$}"

    logger \
        --id="${pid}" \
        -t "${LOGGER_SYSLOG_TAG}" \
        -p "${LOGGER_SYSLOG_FACILITY}.${severity}" \
        "${syslog_line}" ||
        _logger_fatal "logger --id=\"${pid}\" -t \"${LOGGER_SYSLOG_TAG}\" -p \"${LOGGER_SYSLOG_FACILITY}.${severity}\" \"${syslog_line}\""
}

# Fatal error logger for Bash-logger internal
_logger_fatal() {
    msg="${1}"
    printf "\033[0;31mWARNING Bash-Logger FATAL ERROR\033[0m "
    echo "LAST LOG: $msg"
    exit 1
}

# Get values in a posix complaint way
_get_color() {
    case "${level}" in
    "SENSITIVE")
        echo "$COLOR_SENSITIVE"
        ;;
    "DEBUG")
        echo "$COLOR_DEBUG"
        ;;
    "INFO")
        echo "$COLOR_INFO"
        ;;
    "NOTICE")
        echo "$COLOR_NOTICE"
        ;;
    "WARN" | "WARNING")
        echo "$COLOR_WARN"
        ;;
    "ERROR" | "ERR")
        echo "$COLOR_ERROR"
        ;;
    "CRITICAL" | "CRIT")
        echo "$COLOR_CRITICAL"
        ;;
    "ALERT")
        echo "$COLOR_ALERT"
        ;;
    "EMERGENCY" | "EMERG" | "FATAL")
        echo "$COLOR_FATAL"
        ;;
    "DEFAULT")
        echo "$COLOR_DEFAULT"
        ;;
    *)
        echo "$COLOR_DEFAULT"
        ;;
    esac
}

_get_log_level() {
    level="$(printf "%s" "$1" | tr '[:lower:]' '[:upper:]')"
    level="${level#"${level%%[![:space:]]*}"}" # Remove leading space
    level="${level%"${level##*[![:space:]]}"}" # Remove trailing space

    case "${level}" in
    "SENSITIVE")
        echo "$LOGGER_LEVEL_SENSITIVE"
        ;;
    "DEBUG")
        echo "$LOGGER_LEVEL_DEBUG"
        ;;
    "INFO")
        echo "$LOGGER_LEVEL_INFO"
        ;;
    "NOTICE")
        echo "$LOGGER_LEVEL_NOTICE"
        ;;
    "WARN" | "WARNING")
        echo "$LOGGER_LEVEL_WARN"
        ;;
    "ERROR" | "ERR")
        echo "$LOGGER_LEVEL_ERROR"
        ;;
    "CRITICAL" | "CRIT")
        echo "$LOGGER_LEVEL_CRITICAL"
        ;;
    "ALERT")
        echo "$LOGGER_LEVEL_ALERT"
        ;;
    "EMERGENCY" | "EMERG" | "FATAL")
        echo "$LOGGER_LEVEL_FATAL"
        ;;
    *)
        # If it's a number between 0-7 (valid syslog levels), use it directly
        case "$level" in
        [0-7]) echo "$level" ;;
        *) echo "$LOGGER_LEVEL_INFO" ;;
        esac
        ;;
    esac

}

# Setup vars
_setup_colors() {
    NO_COLOR='\033[0m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[01;34m'
    BOLD='\033[01;01m'

    COLOR_SENSITIVE="$YELLOW"
    COLOR_DEFAULT="$NO_COLOR"
    COLOR_DEBUG="$BLUE"
    COLOR_INFO="$GREEN"
    COLOR_NOTICE="$NO_COLOR"
    COLOR_WARN="$YELLOW"
    COLOR_ERROR="$RED"
    COLOR_CRITICAL="$RED"
    COLOR_ALERT="$RED"
    COLOR_FATAL="$BOLD$RED"
}

_setup_logger_levels() {
    LOGGER_LEVEL_SENSITIVE=8 # Only sent to console.
    LOGGER_LEVEL_DEBUG=7     #  Debug: debug-level messages
    LOGGER_LEVEL_INFO=6      #  Informational: informational messages
    LOGGER_LEVEL_NOTICE=5    # Notice: normal but significant condition.
    LOGGER_LEVEL_WARN=4      # Warning: warning conditions
    LOGGER_LEVEL_ERROR=3     # Error: error conditions
    LOGGER_LEVEL_CRITICAL=2  # Critical: critical conditions.
    LOGGER_LEVEL_ALERT=1     #   Alert: action must be taken immediately.
    LOGGER_LEVEL_FATAL=0     #  Fatal/Emergency: system is unusable.
}

_setup_log_path() {
    log_path="${1}"
    if [ ! -e "$log_path" ]; then
        mkdir -p "$log_path"
    fi

    LOGGER_LOG_PATH="$(realpath "$log_path")"
    export LOGGER_LOG_PATH
}

# shellcheck disable=SC2329,SC2317 # disable not used warning, not reachable
_shellcheck_vars() {
    # Not called. for shellcheck in development
    . "../../lint/logging/bash-logger.lint"
}
