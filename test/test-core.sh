#!/bin/sh -E

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# shellcheck source="../src/logger/bash-logger.sh"
. "src/logger/bash-logger.sh"

log_dir=
setup() {
    dir="${1}"
    if [ -e "$dir" ]; then
        rm -rf "$dir"
    fi
    mkdir -p "$dir"
    log_dir=$dir
}

test_log_level_int() {
    echo test_log_level_int
    (
        LOGGER_SETUP 7 "test_log_level_int" "$log_dir"
        echo LOGGER_MIN_LEVEL "$LOGGER_MIN_LEVEL"
        reset
    )

}

test_log_level_string() {
    echo test_log_level_string
    (
        LOGGER_SETUP DEBUG "test_log_level_string" "$log_dir"
        echo LOGGER_MIN_LEVEL "$LOGGER_MIN_LEVEL"
        reset
    )
}

test_log_level_string_mixed_case() {
    echo test_log_level_string_mixed_case
    (
        LOGGER_SETUP Debug "test_log_level_string_mixed_case" "$log_dir"
        echo LOGGER_MIN_LEVEL "$LOGGER_MIN_LEVEL"
        reset
    )
}

test_log_level_array() {
    echo test_log_level_array
    (
        LOGGER_SETUP DebUg "test_log_level_array" "$log_dir"
        echo LOGGER_MIN_LEVEL "$LOGGER_MIN_LEVEL"
        reset
    )
}

test_console() {
    echo test_console
    (
        LOGGER_SETUP DEBUG "test_console" "$log_dir"
        LOGGER_ENABLE_CONSOLE INFO
        LOG "DEBUG" "This is a debug "
        LOG "INFO" "This is a INFO "
        reset
    )
}

test_console_fatal() {
    echo test_console_fatal
    (
        LOGGER_SETUP DEBUG "test_console_fatal" "$log_dir"
        LOGGER_ENABLE_FILE DEBUG
        LOGGER_ENABLE_CONSOLE FATAL
        LOG "DEBUG" "This is a debug WITH FATAL ONLY"
        LOG FATAL fatal
        reset
    )
}

test_file() {
    echo test_file
    (
        LOGGER_SETUP DEBUG "Test File" "$log_dir"
        LOGGER_ENABLE_FILE
        LOG "DEBUG" "This is a debug"
        LOG FATAL fatal
        reset
    )
}

test_is_init() {
    echo test_is_init
    (
        (
            LOGGER_SETUP DEBUG "Test Logger Init"
            if LOGGER_IS_INIT; then
                LOG "DEBUG" "There is a logger"

            else
                LOG "DEBUG" "TEST FAILED"
            fi
            reset
        )

        if LOGGER_IS_INIT; then
            LOG "DEBUG" "There is a logger"

        else
            LOGGER_SETUP DEBUG "Test Logger Init NEW"
            LOG "DEBUG" "TEST PASSED"
        fi
        reset
    )
}

test_json() {
    echo test_json
    (
        LOGGER_SETUP DEBUG "Test Logger JSON"
        LOGGER_ENABLE_JSON DEBUG
        LOG "DEBUG" "JSON - This is a debug"
        LOG FATAL fatal
        reset
    )
}

test_pipe() {
    echo test_pipe
    (
        LOGGER_SETUP DEBUG "Test Logger Pipe" "$log_dir"
        LOGGER_ENABLE_FILE
        efi-readvar | LOG DEBUG -
        reset
    )
}

test_syslog() {
    echo test_syslog
    (
        LOGGER_SETUP DEBUG "Test Logger Syslog"
        LOGGER_ENABLE_SYSLOG DEBUG
        LOG "DEBUG" "Syslog - This is a debug "
        LOG FATAL "Syslog FATAL"
        reset
    )
}

test_throw() {
    echo test_throw
    (

        LOGGER_SETUP DEBUG "Test throw" "$log_dir"
        LOGGER_ENABLE_FILE
        message=$(throw "my message")
        ret=$?
        if [ "$ret" -ne 0 ]; then
            LOG FATAL "$message"
        fi

    )
    reset
}

throw() {
    input="${1}"
    echo "this is a bad block with an input of $input"
    return 1
}

reset() {
    LOGGER_DISPOSE
    echo
    echo
}

run
