#!/bin/sh
opam update
opam switch create . ocaml-base-compiler.4.07.1
export OPAMSOLVERTIMEOUT=3600;
opam list --available -s | xargs opam install --best-effort --yes
