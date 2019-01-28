#!/bin/sh
eval $(opam env)
gh-pages-amend $(odig cache path)/html doc
