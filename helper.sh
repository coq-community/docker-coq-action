#!/bin/bash
# -*- compile-command: "./helper.sh gen"; -*-
# Author: Erik Martin-Dorel, 2020

## Usage
#
# Run (./helper.sh --help)
#
## Overview
#
# Run (./helper.sh gen) to generate min.sh;
# Copy-and-paste min.sh in entrypoint.sh.
#
## Remark
#
# The generated code in min.sh is escaped as needed by entrypoint.sh.
# Replace escape="true" with escape="false" in minimify() if you want
# to test the code locally after doing (./helper.sh gen && . min.sh).

srcdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )

# shellcheck source=./timegroup.sh
. "$srcdir/timegroup.sh"

run_tests() {
    set -e
    if endGroup; then
        echo "FAILURE: endGroup should raise an error"
    else
        echo "Error OK."
    fi
    startGroup
    sleep 1s
    # endGroup
    startGroup This is a test
    sleep 2s
    endGroup
    echo "DONE."
}

minimify() {
    local escape="true"
    # This function is intended to export a minimified version of the
    # specified functions, developed in this file, then incorporated
    # in entrypoint.sh
    for fun; do
        if [ "$escape" = "true" ]; then
            type "$fun" | tail -n+2 | perl -pwe 'chomp; s/ +/ /g; s/}/; }/g; s/\$/\\\$/g; s/"/\\"/g'
        else
            type "$fun" | tail -n+2 | perl -pwe 'chomp; s/ +/ /g; s/}/; }/g'
        fi
    done
}

main_helper () {
    local gen_file="min.sh"
    if [ $# -eq 1 ] && [ "$1" = "test" ]; then
        run_tests
    elif [ $# -eq 1 ] && [ "$1" = "gen" ]; then
        set -x
        exec > "$gen_file"

        echo -n 'exec 2>&1 ; '  # workaround GHA unflushed stdout/stderr
        minimify endGroup
        echo -n ' ; '
        minimify startGroup
        echo ' # generated from helper.sh'
    else
        cat <<EOF
Usage:

  $0 test
    Run tests.

  $0 gen
    Generate '$gen_file'.
EOF
    fi
}

main_helper "$@"
