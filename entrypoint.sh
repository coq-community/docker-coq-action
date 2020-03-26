#!/bin/sh -l
# the docker:latest image relies on alpine; it has no bash by default.

set -e

echorun() {
    echo "$ $*"
    "$@"
}
echorun cat /proc/cpuinfo || true
echorun cat /proc/meminfo || true
echorun cat /etc/os-release || true

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
fi
echo OCAML407="$OCAML407"

echo COQ_IMAGE="$COQ_IMAGE"
docker pull "$COQ_IMAGE"

echo "PWD=$PWD"
# should be /github/workspace

echo PACKAGE="$PACKAGE"
docker run -i --init --rm --name=COQ -e PACKAGE="$PACKAGE" \
       -v "$PWD:$PWD" -w "$PWD" \
       "$COQ_IMAGE" /bin/bash --login -c "
export PS4='+ \e[33;1m(\$0 @ line \$LINENO) \$\e[0m '; set -ex
if [ $OCAML407 = true ]; then opam switch \${COMPILER_EDGE}; eval \$(opam env); fi
$_SCRIPT" script

echo "done"
