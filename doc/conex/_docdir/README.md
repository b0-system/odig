## Conex - establish trust in community repositories

0.10.1

Conex is a utility for verify and attest release integrity and authenticity of community repositories through the use of cryptographic signatures (RSA-PSS-SHA256). It is based on [the update framework](https://theupdateframework.github.io/), especially on their [CCS 2010 paper](https://isis.poly.edu/~jcappos/papers/samuel_tuf_ccs_2010.pdf), and adapted to the requirements of the [opam](https://ocaml.opam.org) [repository](https://github.com/ocaml/opam-repository).

The developer sign their release checksums and build instructions.  A quorum (with a configurable threshold) of repository maintainers signs the package name to developer key relation.  These repository maintainers are enrolled by a quorum of offline root keys.

The [TUF spec](https://github.com/theupdateframework/specification/blob/master/tuf-spec.md) has a good overview of attacks and threat model, both of which are shared by conex.

## Project history

Spring 2017, together with Justin Cappos [TAP 8](https://github.com/theupdateframework/taps/blob/master/tap8.md) was designed which extends TUF with key rotation and explicit self-revocation.

Early 2017, a [blog post](https://hannes.nqsb.io/Posts/Conex) introducing a prototype was published.

We presented [an earlier design at OCaml 2016](https://github.com/hannesm/conex-paper/raw/master/paper.pdf) about an earlier design.

Another article on an [even earlier design (from 2015)](http://opam.ocaml.org/blog/Signing-the-opam-repository/) is also available.

## Installation

`opam instal conex` will install this library and tool,
once you have installed OCaml (>= 4.03.0) and opam (>= 2.0.0beta).

A small test repository with two maintainers is available [here](https://github.com/hannesm/testrepo) including transcripts of how it was setup, and how to setup opams `repo validation hook`.
