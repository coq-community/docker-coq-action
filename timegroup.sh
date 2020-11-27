#!/bin/sh
# Author: Erik Martin-Dorel, 2020

endGroup() {
    # This function unsets the env var '_startTime'.
    { init_opts="$-"; set +x; } 2>/dev/null
    # local _endTime
    if [ -n "$_startTime" ]; then
        # _endTime=$(TZ=UTC+0 printf '%(%s)T\n' '-1')  # not POSIX
        _endTime=$(date -u +%s)
        echo "::endgroup::"
        # TZ=UTC-0 printf '↳ %(%-Hh %-Mm %-Ss)T\n' "$((_endTime - _startTime))"  # not POSIX
        printf "↳ "; date -u -d "@$((_endTime - _startTime))" '+%-Hh %-Mm %-Ss'; echo
        # Assume the time difference < 24h
        unset _startTime
    else
        echo 'Error: missing startGroup command.'
        case "$init_opts" in *x*) set -x; esac
        return 1
    fi
    case "$init_opts" in *x*) set -x; esac
}

startGroup() {
    # This function sets the env var '_startTime'.
    { init_opts="$-"; set +x; } 2>/dev/null
    # Nesting groups is not supported; call 'endGroup' if need be.
    if [ -n "$_startTime" ]; then
        endGroup
    fi
    # local _groupTitle
    if [ $# -ge 1 ]; then
        _groupTitle="$*"
    else
        _groupTitle="Unnamed group"
    fi
    echo
    echo "::group::$_groupTitle"
    unset _groupTitle
    # _startTime=$(TZ=UTC-0 printf '%(%s)T\n' '-1')  # not POSIX
    _startTime=$(date -u +%s)
    case "$init_opts" in *x*) set -x; esac
}
