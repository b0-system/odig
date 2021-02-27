#!/bin/sh
eval $(opam env)
opam update odoc odig
odig odoc -v --odoc-theme=odig.default \
     --index-title 4.11.1 --index-intro=intro.mld
