Encore
======

[![Build Status](https://travis-ci.org/dinosaure/encore.svg?branch=master)](https://travis-ci.org/dinosaure/encore)

Encore is a little library to provide an interface to generate an
[Angstrom](https://github.com/inhabitedtype/angstrom.git)'s decoder and a
internal encoder from a shared description. The goal is specifically for
[ocaml-git](https://github.com/mirage/ocaml-git.git) to ensure isomorphism when
we decode and encode a Git object - and keep the same hash/identifier.

## Examples

A good example can be found in
[`ocaml-git`](https://github.com/mirage/ocaml-git.git). We use `encore` to
describe Git objects, by this way, ensure to re-encode what we decoded without
noises - and keep the same hash.

## Some notes about internal encoder

Internal encoder is a little encoder which takes care about the memory
consumption when you serialize an OCaml value with a description. We use a
bounded bigarray and when it's full, we explicitly ask to the user to flush it.

Internal encoder was built on a CPS mind like Angstrom and uses only pure
functional data structures. This is a big difference from
[Faraday](https://github.com/inhabitedtype/faraday.git). So, obviously, this
encoder is slower than Faraday (3 times), however, we can not use Faraday in
this context, precisely about _alteration_.

In fact, when the encoder fails, we raise an exception to short-cut to the other
branch. With a mutable structure, it's little bit hard to rollback to the old
state of encoder and retry the other branch. With this encoder, we don't need to
trick to rollback because, at any step we make a new pure state.

## Inspirations

This project is inspired by the [finale](https://github.com/takahisa/finale.git)
project which is focused on a pretty-printer at the end. Encore is close to
provide a low-level encoder like
[Faraday](https://github.com/inhabitedtype/faraday.git) than a generator of a
pretty-printer.

## Improvements

This library was made specifically for `ocaml-git`. The API could be not
consistent for an usual user (and not easy to use). So feedbacks are really
welcomed to improve API. Finally, the big issue seems to be performance on
internal encoder - it could be interesting to improve it but it's little-bit
difficult to understand assumptions on encoding process - like immutability. So,
feel free!
