# Docker-Coq action

![reviewdog][reviewdog-badge]
[![coqorg][coqorg-shield]][coqorg-link]
[![mathcomp][mathcomp-shield]][mathcomp-link]
[![Example][example-shield]][example-link]
[![Contributing][contributing-shield]][contributing-link]
[![Code of Conduct][conduct-shield]][conduct-link]

[reviewdog-badge]: https://github.com/coq-community/docker-coq-action/workflows/reviewdog/badge.svg?branch=master

[coqorg-shield]: https://img.shields.io/badge/depends%20on-coqorg%2Fcoq-blue.svg
[coqorg-link]: https://hub.docker.com/r/coqorg/coq

[mathcomp-shield]: https://img.shields.io/badge/see%20also-mathcomp%2Fmathcomp-blue.svg
[mathcomp-link]: https://hub.docker.com/r/mathcomp/mathcomp

[example-shield]: https://img.shields.io/badge/see%20also-example-brightgreen.svg
[example-link]: https://github.com/erikmd/docker-coq-github-action-demo

[contributing-shield]: https://img.shields.io/badge/contributions-welcome-%23f7931e.svg
[contributing-link]: https://github.com/coq-community/manifesto/blob/master/CONTRIBUTING.md

[conduct-shield]: https://img.shields.io/badge/%E2%9D%A4-code%20of%20conduct-%23f15a24.svg
[conduct-link]: https://github.com/coq-community/manifesto/blob/master/CODE_OF_CONDUCT.md

This GitHub action can be used together with
[coqorg/coq](https://hub.docker.com/r/coqorg/coq/) Docker images.

For more details about these images, see the
[docker-coq wiki](https://github.com/coq-community/docker-coq/wiki).

Assuming the Git repository contains a `folder/coq-proj.opam` file,
it will run (by default) the following commands:

```
opam config list; opam repo list; opam list
opam pin add -n -y -k path coq-proj folder
opam update -y
opam install -y -j 2 coq-proj --deps-only
opam list
opam install -y -v -j 2 coq-proj
opam list
opam remove coq-proj
```

## Usage

See [action.yml](./action.yml)

### Example

```yaml
runs-on: ubuntu-latest  # container actions require GNU/Linux
strategy:
  matrix:
    coq_version:
      - '8.11'
      - dev
    ocaml_version: ['4.07-flambda']
  fail-fast: false  # don't stop jobs if one fails
steps:
  - uses: actions/checkout@v2
  - uses: coq-community/docker-coq-action@v1
    with:
      opam_file: 'folder/coq-proj.opam'
      coq_version: ${{ matrix.coq_version }}
      ocaml_version: ${{ matrix.ocaml_version }}
```

See also the [example repo](https://github.com/erikmd/docker-coq-github-action-demo).

### Inputs

#### `opam_file`

*Optional* the path of the `.opam` file (or a directory), relative to the repo root.
Default `"."` (if the argument is omitted or an empty string).

*Note-1:* relying on the value of this `INPUT_OPAM_FILE` variable, the
following two variables are exported when running the `custom_script`:

```
if [ -z "$INPUT_OPAM_FILE" ] || [ -d "$INPUT_OPAM_FILE" ]; then
    WORKDIR=""
    PACKAGE=${INPUT_OPAM_FILE:-.}
else
    WORKDIR=$(dirname "$INPUT_OPAM_FILE")
    PACKAGE=$(basename "$INPUT_OPAM_FILE" .opam)
fi
```

*Note-2:* if this value is a directory (e.g., `.`), relying on the
[`custom_script` default value](#custom_script), the action will
install all the `*.opam` packages stored in this directory.

#### `coq_version`

*Optional* The version of Coq. E.g., `"8.10"`. Default
`"latest"` (= latest stable version).

#### `ocaml_version`

*Optional* The version of OCaml. Default `"minimal"`.
Among `"minimal"` (*deprecated, to be removed on 14 December 2020*),
`"default"`, `"4.02"`, `"4.05"`, `"4.07-flambda"`,
`"4.08-flambda"`, `"4.09-flambda"`, `"4.10-flambda"`, `"4.11-flambda"`.

The supported compilers w.r.t. each version of Coq are documented in the
[Supported tags](https://github.com/coq-community/docker-coq/wiki#supported-tags) section of the `docker-coq` wiki.

#### `before_install`

*Optional* The bash snippet to run before `install`

Default:

```
startGroup "Print opam config"
  opam config list; opam repo list; opam list
endGroup
```

See [`custom_script`](#custom_script) for more details.

#### `install`

*Optional* The bash snippet to install the `opam` `PACKAGE` dependencies.

Default:

```
startGroup "Install dependencies"
  opam pin add -n -y -k path $PACKAGE $WORKDIR
  opam update -y
  opam install -y -j 2 $PACKAGE --deps-only
endGroup
```

See [`custom_script`](#custom_script) for more details.

#### `after_install`

*Optional* The bash snippet to run after `install` (if successful).

Default:

```
startGroup "List installed packages"
  opam list
endGroup
```

See [`custom_script`](#custom_script) for more details.

#### `before_script`

*Optional* The bash snippet to run before `script`. Default `""` (empty string).

See [`custom_script`](#custom_script) for more details.

#### `script`

*Optional* The bash snippet to install the `opam` `PACKAGE`.

Default:

```
startGroup "Build"
  opam install -y -v -j 2 $PACKAGE
  opam list
endGroup
```

See [`custom_script`](#custom_script) for more details.

#### `after_script`

*Optional* The bash snippet to run after `script` (if successful). Default `""` (empty string).

See [`custom_script`](#custom_script) for more details.

#### `uninstall`

*Optional* The bash snippet to uninstall the `opam` `PACKAGE`.

Default:

```
startGroup "Uninstallation test"
  opam remove $PACKAGE
endGroup
```

See [`custom_script`](#custom_script) for more details.

#### `custom_script`

*Optional* The main script run in the container; may be overridden; but overriding more specific parts of the script is preferred.

Default:

```
{{before_install}}
{{install}}
{{after_install}}
{{before_script}}
{{script}}
{{after_script}}
{{uninstall}}
```

*Note-1:* the semantics of this variable is a *standard Bash script*,
that is evaluated within the workflow container after replacing the
"mustache" placeholders with the value of their variable counterpart.
For example, `{{uninstall}}` will be replaced with the value of the
[`uninstall`](#uninstall) variable (the default value of which being
the string `opam remove $PACKAGE`).

*Note-2:* this option is named `custom_script` rather than `run` or so
to **discourage changing its recommended, default value** for building
a regular `opam` project, while keeping the flexibility to be able to
change it.

*Note-3:* if you decide to override the `custom_script` value anyway,
you can just as well rely on the "mustache interpolation" of
`{{before_install}}` … `{{uninstall}}`, and customize the underlying
values.


#### `custom_image`

*Optional* The name of the Docker image to pull; unset by default.

If this variable is unset, its value is computed from the values of
keywords `coq_version` and `ocaml_version`.

If you use the standard
[`docker-coq`](https://github.com/coq-community/docker-coq) images, we
recommend to directly use keywords `coq_version` and `ocaml_version`.

If you use another registry such as that of
[`docker-mathcomp`](https://github.com/math-comp/docker-mathcomp)
images, you can benefit from that keyword by writing a configuration
such as:

```yaml
runs-on: ubuntu-latest
strategy:
  matrix:
    image:
      - mathcomp/mathcomp:1.10.0-coq-8.10
      - mathcomp/mathcomp:1.10.0-coq-8.11
      - mathcomp/mathcomp:1.11.0-coq-dev
      - mathcomp/mathcomp-dev:coq-dev
  fail-fast: false  # don't stop jobs if one fails
steps:
  - uses: actions/checkout@v2
  - uses: coq-community/docker-coq-action@v1
    with:
      opam_file: 'folder/coq-proj.opam'
      custom_image: ${{ matrix.image }}
```

#### `export`

*Optional* A space-separated list of `env` variables to export to the `custom_script`.

*Note-1:* The values of the variables to export may be defined by using the
[`env`](https://docs.github.com/en/free-pro-team@latest/actions/reference/environment-variables)
keyword.

*Note-2:* Regarding the naming of these variables:

* Only use ASCII letters, `_` and digits, i.e., matching the `[a-zA-Z_][a-zA-Z0-9_]*` regexp.
* Avoid [reserved identifiers](https://docs.github.com/en/free-pro-team@latest/actions/reference/environment-variables) (namely: `HOME`, `CI`, and strings starting with `GITHUB_`, `ACTIONS_`, `RUNNER_`, or `INPUT_`).

Here is a minimal working example of this feature:

```yaml
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v2
  - uses: coq-community/docker-coq-action@v1
    with:
      opam_file: 'folder/coq-proj.opam'
      coq_version: 'dev'
      ocaml_version: '4.07-flambda'
      export: 'OPAMWITHTEST'  # space-separated list of variables
    env:
      OPAMWITHTEST: 'true'
```

Here, setting the [`OPAMWITHTEST`](https://opam.ocaml.org/doc/man/opam-install.html#lbAG)
environment variable is useful to run the unit tests
(specified using `opam`'s [`with-test`](http://opam.ocaml.org/doc/Manual.html#pkgvar-with-test)
clause) after the package build.

### Remarks

#### startGroup/endGroup

The default value of fields `{{before_install}}`, `{{install}}`,
`{{after_install}}`, `{{script}}`, and `{{uninstall}}` involves the
functions `startGroup` (taking 1 argument: `startGroup "Group title"`)
and `endGroup`.

These bash functions have the following features:

* they create foldable groups in the GitHub Actions logs
    (see the [online doc](https://github.com/actions/toolkit/blob/master/docs/commands.md#group-and-ungroup-log-lines)),
* and they compute the elapsed time for the considered group;
* these groups cannot be nested,
* and if an `endGroup` has been forgotten, it is implicitly and
  automatically inserted at the next `startGroup` (albeit it is better
  to make each `endGroup` explicit, for readability).

#### Permissions

If you use the
[`docker-coq`](https://github.com/coq-community/docker-coq) images,
the container user has UID=GID=1000 while the GitHub action workdir
has (UID=1001, GID=116).
This is not an issue when relying on `opam` to build the Coq project.
Otherwise, you may want to use `sudo` in the container to change the
permissions. You may also install additional Debian packages.

Typically, this would lead to a workflow specification like this:

```yaml
runs-on: ubuntu-latest
strategy:
  matrix:
    image:
      - 'coqorg/coq:dev'
steps:
  - uses: actions/checkout@v2
  - uses: coq-community/docker-coq-action@v1
    with:
      opam_file: 'coq-demo.opam'
      custom_image: ${{ matrix.image }}
      before_script: |
        startGroup "Workaround permission issue"
          sudo chown -R coq:coq .  # <--
        endGroup
      script: |
        startGroup "Build project"
          make -j2
        endGroup
      uninstall: |
        startGroup "Clean project"
          make clean
        endGroup
  - name: Revert permissions
    # to avoid a warning at cleanup time
    if: ${{ always() }}
    run: sudo chown -R 1001:116 .  # <--
```

For more details, see the
[CI setup / Remarks](https://github.com/coq-community/docker-coq/wiki/CI-setup#remarks)
section in the `docker-coq` wiki.

#### OPAM

The `docker-coq-action` provides built-in support for `opam` builds.

If your project does not already have a `coq-….opam` file, you might
generate one such file by using the corresponding template gathered in
[coq-community/templates](https://github.com/coq-community/templates#readme).

This `.opam` file can then serve as a basis for submitting releases in
[coq/opam-coq-archive](https://github.com/coq/opam-coq-archive), and
related guidelines (including the required **`.opam` metadata**) are
available in <https://coq.inria.fr/opam-packaging.html>.

More details can be found in the
[opam documentation](https://opam.ocaml.org/doc/Packaging.html#The-file-format-in-more-detail).
