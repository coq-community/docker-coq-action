# Docker-Coq action

This GitHub action can be used together with
[coqorg/coq](https://hub.docker.com/r/coqorg/coq/) Docker images.

For more details about these images, see the
[docker-coq wiki](https://github.com/coq-community/docker-coq/wiki).

Assuming the Git repositiory contains a `folder/coq-proj.opam` file,
it will run (by default) the following commands:

```
opam config list; opam repo list; opam list
opam pin add -n -y -k path coq-proj folder
opam update -y
opam install -y -v -j 2 coq-proj
opam list
opam remove coq-proj
```

## Usage

See [action.yml](./action.yml)

### Example

```yaml
strategy:
  matrix:
    coq_version:
      - 8.11
      - dev
    ocaml_version: ['4.07-flambda']
steps:
- uses: actions/checkout@v2
- uses: erikmd/docker-coq-action@alpha
  with:
    opam_file: 'folder/coq-proj.opam'
    coq_version: ${{ matrix.coq_version }}
    ocaml_version: ${{ matrix.ocaml_version }}
```

### Inputs

#### `opam_file`

**Required** the path of the `.opam` file, relative to the repo root.

*Note:* relying on the value of this `INPUT_OPAM_FILE` variable, the
following two variables are exported when running the `custom_script`:

```
WORKDIR=$(dirname "$INPUT_OPAM_FILE")
PACKAGE=$(basename "$INPUT_OPAM_FILE" .opam)
```

See also the
[`custom_script` default value](https://github.com/erikmd/docker-coq-action#custom_script).

#### `coq_version`

*Optional* The version of Coq. E.g., `"8.10"`. Default
`"latest"` (= latest stable version).

#### `ocaml_version`

*Optional* The version of OCaml. Default `"minimal"`.
Among `"minimal"`, `"4.07-flambda"`, `"4.09-flambda"`.

#### `custom_script`

*Optional* The main script run in the container; may be overridden. Default:

    startGroup Print opam config
      opam config list; opam repo list; opam list
    endGroup
    startGroup Fetch dependencies
      opam pin add -n -y -k path $PACKAGE $WORKDIR
      opam update -y
    endGroup
    startGroup Build
      opam install -y -v -j 2 $PACKAGE
      opam list
    endGroup
    startGroup Uninstallation test
      opam remove $PACKAGE
    endGroup

*Note: this option is named `custom-script` rather than `script` or
`run` to discourage changing its recommended, default value, while
keeping the flexibility to be able to change it. This experimental
option might be removed, or replaced with other similar options.*

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
strategy:
  matrix:
    image:
      - mathcomp/mathcomp:1.10.0-coq-8.10
      - mathcomp/mathcomp:1.10.0-coq-8.11
      - mathcomp/mathcomp:1.11.0-coq-dev
      - mathcomp/mathcomp-dev:coq-dev
steps:
- uses: actions/checkout@v2
- uses: erikmd/docker-coq-action@alpha
  with:
    opam_file: 'folder/coq-proj.opam'
    custom_image: ${{ matrix.image }}
```

## TODO/IFNEEDBE

* We should document the contents/generation of a Coq `.opam` file
  (e.g., with a link to coq-community templates)
* We might want to replace the `custom_script` option with `script`,
  `after_script`, etc.
