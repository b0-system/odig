#!/bin/sh
eval $(opam env)
opam upgrade odoc odig

OCAML_VERSION=$(opam info -f version ocaml)
ODOC_VERSION=$(opam info -f source-hash odoc)
ODIG_VERSION=$(opam info -f source-hash odig)

sed -e "s/OCAML_VERSION/$OCAML_VERSION/g" \
    -e "s/ODOC_VERSION/$ODOC_VERSION/g" \
    -e "s/ODIG_VERSION/$ODIG_VERSION/g" intro.mld > intro-subst.mld

odig odoc -v --odoc-theme=odig.default --index-title $OCAML_VERSION \
     --index-intro=intro-subst.mld

rm intro-subst.mld
