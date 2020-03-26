# Docker-Coq action

This GitHub action relies on
[coqorg/coq](https://hub.docker.com/r/coqorg/coq/) Docker images.

For more details about these images, see the
[docker-coq wiki](https://github.com/coq-community/docker-coq/wiki).

Assuming the Git repositiory contains a `foo.opam` file, it will run
(by default) the following commands:

```
opam config list; opam repo list; opam list
opam pin add -n -y -k path foo .
opam update -y
opam install -y -v -j 2 foo
opam list
opam remove foo
```

## Inputs

### `opam-file`

**Required** the path of the `.opam` file, relative to the repo root.

### `coq-version`

*Optional* The version of Coq. E.g., `"8.10"`. Default
`"latest"` (= latest stable version).

### `ocaml-version`

*Optional* The version of OCaml. Default `"minimal"`.
Among `"minimal"`, `"4.07-flambda"`, `"4.09-flambda"`.

### `custom-script`

*Optional* The main script run in the container; may be overridden. Default:

    opam config list; opam repo list; opam list
    opam pin add -n -y -k path $PACKAGE .
    opam update -y
    opam install -y -v -j 2 $PACKAGE
    opam list
    opam remove $PACKAGE

*Note: this option is named `custom-script` rather than `script` or
`run` to discourage changing its recommended, default value, while
keeping the flexibility to be able to change it. This experimental
option might be removed, or replaced with other similar options.*

## Example usage

```yaml
uses: erikmd/docker-coq-action@alpha
with:
  opam-file: 'foo.opam'
  coq-version: 'dev'
  ocaml-version: '4.07-flambda'
```

## TODO/IFNEEDBE

* We should document the contents/generation of a Coq `.opam` file
  (e.g., with a link to coq-community templates)
* We might want to replace the `custom-script` option with `script`,
  `after_script`, etc.
* We might want to allow the user to override the name of the
  underlying (docker-coq) image
