#!/bin/sh -E

###########################################################################
# Copyright (c) 2025 by Richard Sperry
# Licensed under the terms of the GPL v3
# Author: Richard Sperry <Richard@SperryFamily.net>
###########################################################################

# shellcheck source="../src/logger/bash-logger.sh"
. "src/logger/bash-logger.sh"

. "test/test-core.sh"

log_dir="logs"

run() {
    clear
    setup "$log_dir"
    test_log"_level_"int
    test_log_level_string
    test_log_level_string_mixed_case
    test_log_level_array
    test_console
    test_console_fatal
    test_file
    test_is_init
    test_json
    test_pipe
    test_syslog
    test_throw
}

run

exit 0
