#!/bin/sh
opam update
opam switch create . ocaml-base-compiler.4.11.1

## 2021 this no longer works even after a full day trying to find for a
## solution.

export OPAMSOLVERTIMEOUT=3600;
opam list --available -s | xargs opam install --best-effort --yes
