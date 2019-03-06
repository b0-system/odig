sslconf — an OCaml version of Openssl's NCONF library
-------------------------------------------------------------------------------
0.8.3

sslconf is a reimplementation of the Openssl NCONF library in OCaml.

NCONF reads Openssl config files. It delivers a data structure and
a query API. Under the data structure are hash tables with strings
and name-value stacks as values. The query API hides details of
implementation.

sslconf has only OCaml code, so it can be used in a unikernel.

sslconf is distributed under the ISC license.

Homepage: https://github.com/awuersch/sslconf  

## Openssl Config File Features

Openssl NCONF documentation is [here][nconf].

[nconf]: https://www.openssl.org/docs/manmaster/man5/config.html

Features of interest in config files:

* namespace support.
Names are mapped to values within namespace-like sections.
* the NCONF query ("get value", "get section") API.
Values mapped to names in sections can be queried. Also, sections as a
whole can be queried and returned as a stack of name-value pairs.
* default names.
A default section lets one define names which are valid in any section
(if not redefined).
* name references inside values.
References to names in the same section ("unqualified" names) or in other
sections ("qualified" names) can be embedded in values.
Forward references are *not* supported.
* environment variable support.
Environment variables can be referenced in values as qualified names
with section "ENV".
* comments. Comments start with a hash character (`#`),
and extend to the end of a line.
* escapes. An escape character (`\`) can
denote a whitespace control character
(if followed by '`n`', '`r`', '`h`', or '`t`'),
or it can force inclusion of the character which follows it.
If at the end of a line,
an escape character requests a line continuation, i.e.,
to join the next line to the current line.
* quote-wrapped parts.
Double quotes or single quotes in values can surround substrings.
Variable expansion is not applied to these substrings. Instances of
the other quote also do not get interpreted.

In addition to NCONF features, this implementation adds serialization of
NCONF structures to OCaml s-expressions.

## Why NCONF? Why Openssl config files? Why config files?

Openssl config files are often recommended for SSL/TLS applications.

Values in Openssl configs are open to different (Unicode or other)
encodings.

It is better
to put secrets or sensitive data in a config file,
than
to expose them *via* command line arguments or environment variables.
Process status command outputs can show
command lines and environment variables to anyone
(and may be transferred to centralized monitoring),
whereas access to a config file can be limited to selected users.

Features of Openssl config files (see above) may be useful.

## Installation

sslconf can be installed with `opam`:

    opam install sslconf

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Future Applications (or, what this library does not do)

This library does one thing well. It parses Openssl config files and
converts them to a type isomorphic to Openssl CONF structs.

Openssl applications, and the Openssl crypto library, use CONF structs
in many contexts.

Analogous applications are not implemented here.  Hopefully, this work
will lead to some.

An application of NCONF in Openssl is [here][nconf-x509v3_config].

[nconf-x509v3_config]: https://www.openssl.org/docs/manmaster/man5/x509v3_config.html

Another application of NCONF is [here][asn1-generate].

[asn1-generate]: https://www.openssl.org/docs/manmaster/man3/ASN1_generate_nconf.html

## Documentation

Openssl NCONF documentation is [here][nconf-config].

[nconf-config]: https://www.openssl.org/docs/manmaster/man5/config.html

Our documentation and API reference is generated from source
interfaces. It can be consulted [online][doc] or via `odig doc
sslconf`.

[doc]: https://awuersch.github.io/sslconf/doc

## Example Programs

Directory `examples` has code for executables.

* `sslconf_show_config` shows function `Sslconf.conf_load_file`.
* `sslconf_show_section` shows function `Sslconf.conf_get_section`.
* `sslconf_show_value` shows function `Sslconf.conf_get_value`.

## Test Coverage

The library has a test suite with near-100% coverage.

Go [here][coverage] for a current coverage report.

[coverage]: https://awuersch.github.io/sslconf/coverage

A few cases are explicitly ignored.
These cases satisfy the type checker, but can never happen.

## Building, Testing, and Documentation from Source

To build:

    cd lib
    make build

To run tests:

    cd lib
    make runtest

To test with `bisect_ppx` test coverage:

    (add "bisect_ppx -conditional" to the preprocess line in lib/jbuild)
    cd lib
    make coverage

A coverage report is copied to the `_coverage` directory.

To generate documentation:

    cd lib
    make doc

Generated documentation is copied to the `doc` directory.

To clean up,

    cd lib
    make clean

### Support Code and Files

`sslconf_dumpcases` dumps test cases to config files in a directory,
which must be empty or will be created.

`sslconf_test` creates and writes out a file `cases.out` in the directory
it is run in. Usually, this directory is `_build/default/test`.

File `cases.out` rewrites the `Testcase` module, with expect strings set
to the result of running `sslconf_test`.

If `test/testcase.ml` is replaced by `cases.out`, and `sslconf` is rebuilt,
all tests should run successfully.

A directory `c` holds a C language program `dump_config.c` which calls
Openssl to dump config information. It can be used to compare Openssl
output to outputs from this implementation.

## Acknowledgements

Thanks to the implementers of the Astring and Bisect_ppx packages, and to
the implementers of the Jbuilder and Topkg packages which made structuring
and building this a pleasure. Also, thanks to the implementers of the more
general packages Sexplib, Ppx_sexp_conv, and OUnit2. A final thanks to the
sponsors and maintainers of Travis-CI, Github, and OPAM.
