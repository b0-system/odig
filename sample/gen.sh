#!/bin/sh
eval $(opam env)
opam update odig
odig odoc -v --odoc-theme=odig.light \
             --index-title 4.07.1 --index-intro=intro.mld
