#!/bin/bash -E

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

LOGGER_DISPOSE() {
    # Vars
    unset LOGGER_DATE_FORMAT
    unset LOGGER_NAME

    # Log levels
    unset LOGGER_MIN_LEVEL
    unset LOGGER_CONSOLE_LEVEL
    unset LOGGER_FILE_LEVEL
    unset LOGGER_JSON_LEVEL
    unset LOGGER_SYSLOG_LEVEL

    # Enabled Loggers
    unset LOGGER_ENABLE_FILE
    unset LOGGER_ENABLE_SYSLOG
    unset LOGGER_ENABLE_JSON
    unset LOGGER_ENABLE_CONSOLE

    # File Paths
    unset LOGGER_LOG_PATH
    unset LOGGER_LOG_FILE_PATH
    unset LOGGER_LOG_JSON_PATH
}
