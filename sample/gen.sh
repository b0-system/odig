#!/bin/sh

eval $(opam env)
opam update odig
odig odoc -v --index-title 4.07.1 --index-intro=intro.mld
