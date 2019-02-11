# Lwt_ssl: OpenSSL binding with concurrent I/O

An Lwt-enabled wrapper around [Ocaml-SSL][ocaml-ssl], that performs I/O
concurrently. Ocaml-SSL, in turn, is a binding to the much-used
[OpenSSL][openssl].

To install, do `opam install lwt_ssl`.

For documentation, see the [`.mli` file][mli].

This package was formerly maintained in the [main Lwt repo][lwt]. Most of the
git history and changelog still refer to Lwt_ssl's days in Lwt.



[ocaml-ssl]: https://github.com/savonet/ocaml-ssl
[openssl]: https://www.openssl.org/
[mli]: https://github.com/aantron/lwt_ssl/blob/master/src/lwt_ssl.mli
[lwt]: https://github.com/ocsigen/lwt
