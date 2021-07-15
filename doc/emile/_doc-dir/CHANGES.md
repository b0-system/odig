### v1.1 2020-11-19 Paris (France)

- Add some tests to check the behavior of the pretty-printer (@dinosaure, #14)
- Fix the implementation of the quoted-string (@dinosaure, #14)
- Fix internal list pretty-printer (discovered by @hannes, @dinosaure, #14)

### v1.0 2020-09-18 Paris (France)

- Add `to_string` functions to emit email addresses
- Better error message (**breaking-change**)

### v0.9 2020-05-05 Paris (France)

- Update to `angstrom.0.14.0`

### v0.8 2020-03-14 Paris (France)

- `dune` is no longer a _build_ dependency
- fix pretty-printers
- fix comparison functions
- add tests about comparison functions
- delete useless internal functions
- clean the distribution (and delete `fmt` dependency)

### v0.7 2020-01-23 Paris (France)

- Fix support of UTF-8 (@dinosaure)
- Remove support of `mrmime`
  `mrmime` will finally use `emile` as the parser of email address.
- Externalize some parsers:
	+ `address_list`
	+ `mailbox_list`
	+ `group`
	+ `address`
- Handle general-address (domain part) according RFC 5321 and split
  tests about the correctness of IPv6 values

### v0.6 2019-12-10 Paris (France)

- Decomplexify parser and avoid FWS token
- Rewrite `compare` and `equal` functions
- Internal clean of parsers

### v0.5 2019-07-24 Мостар (Боснa и Херцеговина)

- Add helpers about [mrmime](https://github.com/mirage/mrmime.git) (@dinosaure)
- Add CI about optional sub-package `emile.mrmime`
- Update OPAM file (@dinosaure)

### v0.4 2019-07-02 Paris (France)

- **breaking-change** Emile does not handle `FWS` anymore and consider it as basic whitespaces
- Update documentation
- Use `pecu` to decode quoted-printable _encoded-word_
- Use last major version of `base64` to decode base64 _encoded-word_
- Provide `emile.cmdliner` to be able to parse an email as an option of a binary

### v0.3 2018-04-27 Paris (France)

- Update documentation
- Provide `angstrom` parser

### v0.2 2018-03-08 Marrakech (Maroc)

- Update to angstrom.0.9
- Fix CRLF on common parsing function
- Better API to parse e-mail address, e-mail address list, etc.

### v0.1 2018-02-22 Phnom-Penh (Cambodia)

- First release
