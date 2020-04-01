#!/bin/sh -l
# the docker:latest image relies on alpine; it has no bash by default.

set -e

timegroup_file="/app/timegroup.sh"
# shellcheck source=./timegroup.sh
. "$timegroup_file"

startGroup Print runner configuration

echo "GITHUB_WORKFLOW=$GITHUB_WORKFLOW"
echo "RUNNER_OS=$RUNNER_OS"
echo "RUNNER_TEMP=$RUNNER_TEMP"
echo "RUNNER_WORKSPACE=$RUNNER_WORKSPACE"

echorun() {
    echo "$ $*"
    "$@"
}
echorun cat /proc/cpuinfo || true
echorun cat /proc/meminfo || true
echorun cat /etc/os-release || true

endGroup

## Initial values
PACKAGE=""
_OPAM_FILE=""
_COQ_VERSION=""
_OCAML_VERSION=""
_SCRIPT=""

usage() {
    cat <<EOF
Usage:
  $0 -f fil.opam -c 8.11 -m 4.05 -s ''

Options:
-f OPAM_FILE: The path of the .opam file, relative to the repo root.
-c COQ_VERSION: The minor version of Coq.
-m OCAML_VERSION: The minor version of OCaml (4.05, 4.07-flambda, 4.09-flambda)
-s SCRIPT: The main script run in the container.
EOF
}

## Parse options
OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hf:c:m:s:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        f)
            _OPAM_FILE="$OPTARG"
            ;;
        c)
            _COQ_VERSION="$OPTARG"
            ;;
        m)
            _OCAML_VERSION="$OPTARG"
            ;;
        s)
            _SCRIPT="$OPTARG"
            ;;
        '?')
            usage
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional "--".

if test $# -gt 0; then
    echo "Warning: Arguments ignored: $*"
fi

if test -z "$_OPAM_FILE"; then
    echo "ERROR: No opam file specified."
    usage
    exit 1
fi

if test -z "$_COQ_VERSION"; then
    echo "ERROR: No Coq version specified."
    usage
    exit 1
fi

if test -z "$_OCAML_VERSION"; then
    echo "ERROR: No OCaml version specified."
    usage
    exit 1
fi

if test -z "$_SCRIPT"; then
    echo "ERROR: The specified script is empty."
    usage
    exit 1
fi

PACKAGE=${_OPAM_FILE%.opam}
PACKAGE=${PACKAGE##*/}
# todo: test pinning when _OPAM_FILE contains a '/'

# TODO: validation of COQ_VERSION, OCAML_VERSION

COQ_IMAGE="coqorg/coq:$_COQ_VERSION"

# todo: update this after the one-switch docker-coq migration
OCAML407="false"
if [ "$_OCAML_VERSION" = '4.09-flambda' ]; then
    COQ_IMAGE="${COQ_IMAGE}-ocaml-4.09.0-flambda"
elif [ "$_OCAML_VERSION" = '4.07-flambda' ]; then
    OCAML407="true"
# else Assume "$_OCAML_VERSION" = 'minimal'
fi
echo OCAML407="$OCAML407"

startGroup Pull docker-coq image

echo COQ_IMAGE="$COQ_IMAGE"
docker pull "$COQ_IMAGE"

endGroup

# Assuming you used https://github.com/actions/checkout,
# the GITHUB_WORKSPACE variable corresponds to the following host dir:
# ${RUNNER_WORKSPACE}/${GITHUB_REPOSITORY#*/}, see also
# https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables

HOST_WORKSPACE_REPO="${RUNNER_WORKSPACE}/${GITHUB_REPOSITORY#*/}"
echo "HOST_WORKSPACE_REPO=$HOST_WORKSPACE_REPO"

# echorun pwd
## should be /github/workspace
# echorun ls -hal

if [ "$OCAML407" = "true" ]; then
    # shellcheck disable=SC2016
    _OCAML407_COMMAND='opam switch ${COMPILER_EDGE}; eval $(opam env)'
else
    _OCAML407_COMMAND=''
fi

## Note to docker-coq-action maintainers: Run ./helper.sh gen & Copy min.sh
echo PACKAGE="$PACKAGE"
docker run -i --init --rm --name=COQ -e PACKAGE="$PACKAGE" \
       -v "$HOST_WORKSPACE_REPO:$PWD" -w "$PWD" \
       "$COQ_IMAGE" /bin/bash --login -c "
endGroup () {  init_opts=\"\$-\"; set +x; if [ -n \"\$startTime\" ]; then endTime=\$(date -u +%s); echo \"::endgroup::\"; printf \"↳ \"; date -u -d \"@\$((endTime - startTime))\" '+%-Hh %-Mm %-Ss'; echo; unset startTime; else echo 'Error: missing startGroup command.'; case \"\$init_opts\" in  *x*) set -x ;; esac; return 1; fi; case \"\$init_opts\" in  *x*) set -x ;; esac; } ; startGroup () {  init_opts=\"\$-\"; set +x; if [ -n \"\$startTime\" ]; then endGroup; fi; if [ \$# -ge 1 ]; then groupTitle=\"\$*\"; else groupTitle=\"Unnamed group\"; fi; echo; echo \"::group::\$groupTitle\"; startTime=\$(date -u +%s); case \"\$init_opts\" in  *x*) set -x ;; esac; } # generated from helper.sh
export PS4='+ \e[33;1m(\$0 @ line \$LINENO) \$\e[0m '; set -ex
$_OCAML407_COMMAND
$_SCRIPT" script

echo "done"
