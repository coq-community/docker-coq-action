#!/bin/sh -l
# the docker:latest image relies on alpine; it has no bash by default.

set -e

timegroup_file="/app/timegroup.sh"
# shellcheck source=./timegroup.sh
. "$timegroup_file"

if [ -z "$INPUT_OPAM_FILE" ] || [ -d "$INPUT_OPAM_FILE" ]; then
    WORKDIR=""
    PACKAGE=${INPUT_OPAM_FILE:-.}
else
    WORKDIR=$(dirname "$INPUT_OPAM_FILE")
    PACKAGE=$(basename "$INPUT_OPAM_FILE" .opam)
fi

startGroup "Print runner configuration"

echo "GITHUB_WORKFLOW=$GITHUB_WORKFLOW"
echo "RUNNER_OS=$RUNNER_OS"
echo "RUNNER_TEMP=$RUNNER_TEMP"
echo "RUNNER_WORKSPACE=$RUNNER_WORKSPACE"
# Assuming you used https://github.com/actions/checkout,
# the GITHUB_WORKSPACE variable corresponds to the following host dir:
# ${RUNNER_WORKSPACE}/${GITHUB_REPOSITORY#*/}, see also
# https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables
HOST_WORKSPACE_REPO="${RUNNER_WORKSPACE}/${GITHUB_REPOSITORY#*/}"
echo "HOST_WORKSPACE_REPO=$HOST_WORKSPACE_REPO"
echo "HOME=$HOME"
echo

echo "INPUT_COQ_VERSION=$INPUT_COQ_VERSION"
echo "INPUT_OCAML_VERSION=$INPUT_OCAML_VERSION"
echo "INPUT_OPAM_FILE=$INPUT_OPAM_FILE"
echo "INPUT_EXPORT='$INPUT_EXPORT'"
echo "WORKDIR=$WORKDIR"
echo "PACKAGE=$PACKAGE"

echorun() {
    echo "$ $*"
    "$@"
}
echorun cat /etc/os-release || true
echorun cat /proc/cpuinfo || true
echorun cat /proc/meminfo || true

endGroup

usage() {
    cat <<EOF
Usage:
  INPUT_OPAM_FILE=file.opam \\
  INPUT_COQ_VERSION=8.11 \\
  INPUT_OCAML_VERSION=minimal \\
  INPUT_CUSTOM_SCRIPT='...' \\
  INPUT_CUSTOM_IMAGE=''
  INPUT_EXPORT=''
  $0

Options:
INPUT_OPAM_FILE: the path of the .opam file (or a directory), relative to the repo root
INPUT_COQ_VERSION: the version of Coq (without patch-level)
INPUT_OCAML_VERSION: the version of OCaml (minimal, 4.07-flambda, 4.09-flambda)
INPUT_CUSTOM_SCRIPT: the main script run in the container
INPUT_CUSTOM_IMAGE: the name of the Docker image to pull
INPUT_EXPORT: the space-separated list of env variables to export
EOF
}

## Parse options
OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "h" opt; do
    case "$opt" in
        h)
            usage
            exit 0
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

if test -z "$INPUT_CUSTOM_IMAGE"; then
    if test -z "$INPUT_COQ_VERSION"; then
        echo "ERROR: No Coq version specified."
        usage
        exit 1
    fi

    if test -z "$INPUT_OCAML_VERSION"; then
        echo "ERROR: No OCaml version specified."
        usage
        exit 1
    fi

    # TODO: validation of INPUT_COQ_VERSION, INPUT_OCAML_VERSION
    COQ_IMAGE="coqorg/coq:$INPUT_COQ_VERSION"

    # TODO: update this after the one-switch docker-coq migration
    if [ "$INPUT_OCAML_VERSION" = '4.07-flambda' ]; then
	OCAML407="true"
    elif [ "$INPUT_OCAML_VERSION" = 'minimal' ]; then
	OCAML407="false"
    elif [ "$INPUT_OCAML_VERSION" = '4.05' ]; then
	OCAML407="false"
    else
	OCAML407="false"
	COQ_IMAGE="${COQ_IMAGE}-ocaml-${INPUT_OCAML_VERSION}"
    fi
else
    COQ_IMAGE="$INPUT_CUSTOM_IMAGE"
    # TODO: update this after the one-switch docker-coq migration
    OCAML407="false"
fi

if test -z "$INPUT_CUSTOM_SCRIPT"; then
    echo "ERROR: The specified script is empty."
    usage
    exit 1
fi

if printf "%s" "$INPUT_EXPORT" | grep -e '^[a-zA-Z_][a-zA-Z0-9_ ]*$' -q -v; then
    echo "ERROR: The export field is incorrect."
    usage
    exit 1
fi

startGroup "Install perl for mustache interpolation"

apk add --no-cache perl

moperl() {
    re="$1"  # pattern to replace, without the surrounding {{ }}'s
    str="$2"
    perl -wpe 'BEGIN {$re=shift @ARGV; $str=shift @ARGV;}; s/\{\{$re\}\}/$str/g;' "$re" "$str"
}

INPUT_CUSTOM_SCRIPT_EXPANDED=$(printf "%s" "$INPUT_CUSTOM_SCRIPT" | \
  moperl before_install "$INPUT_BEFORE_INSTALL" | \
  moperl install "$INPUT_INSTALL" | \
  moperl after_install "$INPUT_AFTER_INSTALL" | \
  moperl before_script "$INPUT_BEFORE_SCRIPT" | \
  moperl script "$INPUT_SCRIPT" | \
  moperl after_script "$INPUT_AFTER_SCRIPT" | \
  moperl uninstall "$INPUT_UNINSTALL")

endGroup

if test -z "$INPUT_CUSTOM_SCRIPT_EXPANDED"; then
    echo "ERROR: The expanded script is empty."
    usage
    exit 1
fi

startGroup "Pull docker image"

echo COQ_IMAGE="$COQ_IMAGE"
docker pull "$COQ_IMAGE"

# TODO: update this after the one-switch docker-coq migration
echo OCAML407="$OCAML407"

endGroup

if [ "$OCAML407" = "true" ]; then
    # shellcheck disable=SC2016
    _OCAML407_COMMAND='startGroup Change opam switch; opam switch ${COMPILER_EDGE}; eval $(opam env); endGroup'
else
    _OCAML407_COMMAND=''
fi

cp /app/coq.json "$HOME/coq.json"
echo "::add-matcher::$HOME/coq.json"

## Note to docker-coq-action maintainers: Run ./helper.sh gen & Copy min.sh
# shellcheck disable=SC2046,SC2086
docker run -i --init --rm --name=COQ $( [ -n "$INPUT_EXPORT" ] && printf -- "-e %s " $INPUT_EXPORT ) -e WORKDIR="$WORKDIR" -e PACKAGE="$PACKAGE" \
       -v "$HOST_WORKSPACE_REPO:$PWD" -w "$PWD" \
       "$COQ_IMAGE" /bin/bash --login -c "
exec 2>&1 ; endGroup () {  {  init_opts=\"\$-\"; set +x ; } 2> /dev/null; if [ -n \"\$startTime\" ]; then endTime=\$(date -u +%s); echo \"::endgroup::\"; printf \"↳ \"; date -u -d \"@\$((endTime - startTime))\" '+%-Hh %-Mm %-Ss'; echo; unset startTime; else echo 'Error: missing startGroup command.'; case \"\$init_opts\" in  *x*) set -x ;; esac; return 1; fi; case \"\$init_opts\" in  *x*) set -x ;; esac; } ; startGroup () {  {  init_opts=\"\$-\"; set +x ; } 2> /dev/null; if [ -n \"\$startTime\" ]; then endGroup; fi; if [ \$# -ge 1 ]; then groupTitle=\"\$*\"; else groupTitle=\"Unnamed group\"; fi; echo; echo \"::group::\$groupTitle\"; startTime=\$(date -u +%s); case \"\$init_opts\" in  *x*) set -x ;; esac; } # generated from helper.sh
export PS4='+ \e[33;1m(\$0 @ line \$LINENO) \$\e[0m '; set -ex
$_OCAML407_COMMAND
$INPUT_CUSTOM_SCRIPT_EXPANDED" script

echo "::remove-matcher owner=coq-problem-matcher::"
