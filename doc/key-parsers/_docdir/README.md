[![Build Status](https://travis-ci.org/cryptosense/key-parsers.svg?branch=master)](https://travis-ci.org/cryptosense/key-parsers) [![docs](https://img.shields.io/badge/doc-online-blue.svg)](https://cryptosense.github.io/key-parsers/doc/)

# `Key-parsers`

`Key-parsers` offers parsers and printers for various asymmetric key formats.

It currently comes with three submodules.

## `Asn1`

Note that all the parsers in this module expect the raw DER encoded byte string. They don't handle
PEM armoring (`----BEGIN X----` and `----END X----`) nor decode Base64 or hex.

Here you can find parsers for the following formats:

  - PKCS#1 encoding of RSA Private and Public keys as defined in
[PKCS#1 v2.2](https://tools.ietf.org/html/rfc8017#appendix-A)
  - PKCS#8 encoding of RSA, DSA, EC and DH Private keys as defined in
[RFC5208](https://tools.ietf.org/html/rfc5208#section-5)
  - X509 SubjectPublicKeyInfo encoding of RSA, DSA, EC and DH Public keys as defined in
[RFC5280](https://tools.ietf.org/html/rfc5280#appendix-A)
  - DER encodings of DSA, EC and DH Parameters and Private keys as produced by openssl
commands such as `dsaparam` and `gendsa`

## `Ltpa`

Parsers for LTPA (Ligthweight Third Party Authentication) encodings of RSA Private and Public keys.

## `Cvc`

Parsers for CVC (Card Verifiable Certificates) encodings of RSA and EC Public keys.
