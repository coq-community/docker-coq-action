# Docker-Coq action

This GitHub action relies on
[coqorg/coq](https://hub.docker.com/r/coqorg/coq/) Docker images.

For more details about these images, see the
[docker-coq wiki](https://github.com/coq-community/docker-coq/wiki).

Assuming the Git repositiory contains a `foo.opam` file, it will run
the following commands:

```
opam pin add -n -y -k path foo .
opam update -y
opam install -y -v -j 2 foo
```

## Inputs

### `opam-file`

**Required** the path of the `.opam` file, relative to the repo root.

### `coq-version`

*Optional* The minor version of Coq. E.g., `"8.10"`. Default
`"latest"` (= latest stable version).

### `ocaml-version`

*Optional* The minor version of OCaml. Default `"4.05"`. Among
`"4.05"`, `"4.07-flambda"`, `"4.09-flambda"`.

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
* We may want to manually specify a command/script in lieu of these
  `opam` commands
* We might want to allow the user to override the name of the
  underlying (docker-coq) image
