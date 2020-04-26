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

```bash
opam config list; opam repo list; opam list
opam pin add -n -y -k path coq-proj folder
opam update -y
opam install -y -j 2 coq-proj --deps-only
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
      - 8.11
      - dev
    ocaml_version: ['4.07-flambda']
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

**Required** the path of the `.opam` file, relative to the repo root.

*Note:* relying on the value of this `INPUT_OPAM_FILE` variable, the
following two variables are exported when running the `custom_script`:

```bash
WORKDIR=$(dirname "$INPUT_OPAM_FILE")
PACKAGE=$(basename "$INPUT_OPAM_FILE" .opam)
```

See also the
[`custom_script` default value](#custom_script).

#### `coq_version`

*Optional* The version of Coq. E.g., `"8.10"`. Default
`"latest"` (= latest stable version).

#### `ocaml_version`

*Optional* The version of OCaml. Default `"minimal"`.
Among `"minimal"`, `"4.07-flambda"`, `"4.09-flambda"`.

#### `custom_script`

*Optional* The main script run in the container; may be overridden. Default:

```
startGroup Print opam config
  opam config list; opam repo list; opam list
endGroup
startGroup Build dependencies
  opam pin add -n -y -k path $PACKAGE $WORKDIR
  opam update -y
  opam install -y -j 2 $PACKAGE --deps-only
endGroup
startGroup Build
  opam install -y -v -j 2 $PACKAGE
  opam list
endGroup
startGroup Uninstallation test
  opam remove $PACKAGE
endGroup
```

*Note-1:* if you use the `docker-coq` images, the container user has
UID=GID=1000 while the GitHub action workdir has (UID=1001, GID=116).
This is not an issue when relying on `opam` to build the Coq project.
Otherwise, you may want to use `sudo` in the container to change the
permissions. You may also install additional Debian packages.

For more details, see the
[CI setup / Remarks](https://github.com/coq-community/docker-coq/wiki/CI-setup#remarks)
section in the `docker-coq` wiki.

*Note-2: this option is named `custom_script` rather than `script` or
`run` to discourage changing its recommended, default value, while
keeping the flexibility to be able to change it.*

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
steps:
- uses: actions/checkout@v2
- uses: coq-community/docker-coq-action@v1
  with:
    opam_file: 'folder/coq-proj.opam'
    custom_image: ${{ matrix.image }}
```

### Remarks

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
