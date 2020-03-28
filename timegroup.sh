#!/bin/sh
# Author: Erik Martin-Dorel, 2020

endGroup() {
    # This function unsets the env var 'startTime'.
    init_opts="$-"; set +x
    # local endTime
    if [ -n "$startTime" ]; then
        # endTime=$(TZ=UTC+0 printf '%(%s)T\n' '-1')  # not POSIX
        endTime=$(date -u +%s)
        echo "::endgroup::"
        # TZ=UTC-0 printf '↳ %(%-Hh %-Mm %-Ss)T\n' "$((endTime - startTime))"  # not POSIX
        printf "↳ "; date -u -d "@$((endTime - startTime))" '+%-Hh %-Mm %-Ss'; echo
        # Assume the time difference < 24h
        unset startTime
    else
        echo 'Error: missing startGroup command.'
        case "$init_opts" in *x*) set -x; esac
        return 1
    fi
    case "$init_opts" in *x*) set -x; esac
}

startGroup() {
    # This function sets the env var 'startTime'.
    init_opts="$-"; set +x
    # Nesting groups is not supported; call 'endGroup' if need be.
    if [ -n "$startTime" ]; then
        endGroup
    fi
    # local groupTitle
    if [ $# -ge 1 ]; then
        groupTitle="$*"
    else
        groupTitle="Unnamed group"
    fi
    echo
    echo "::group::$groupTitle"
    # startTime=$(TZ=UTC-0 printf '%(%s)T\n' '-1')  # not POSIX
    startTime=$(date -u +%s)
    case "$init_opts" in *x*) set -x; esac
}
