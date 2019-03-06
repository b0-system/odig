## 0.10.1

*2018-10-31*

### Fixes

- Allow RSA parameters to be absent form the AlgorithmIdentifier Sequence

## 0.10.0

*2018-08-27*

### Add

- Lowercase aliases for uppercase modules `RSA`, `DSA`, `EC` and `DH` in `Asn1`, `Cvc` and `Ltpa`

### Deprecates

- `Yojson` and `Bin_prot` (de)serializers are deprecated ahead of their removal in `1.0.0`.
- Uppercase modules such as `Asn1.RSA` in favor of their lowercase counterparts

### Changes

- Use dune instead of ocamlbuild and topkg
- Rename uppercase private variants and modules to lowercase ones

## 0.9.2

*2017-12-12*

- Switch to `asn1-combinators >= 0.2.0`
- Refactor `Kp_asn1`
- Add documentation and README

## 0.9.1

*2017-08-30*

- remove `@tailcall` annotations to allow `ppx_deriving > 4.2`

## 0.9.0

*2017-06-21*

- encode Cstruct as 0x prefixed hex string (breaks json compatibility)

## 0.8.1

*2017-05-03*

- `ppx_bin_prot` 0.9.0 compatibility

## 0.8.0

*2016-12-27*

- Add an `equal` function for all exposed types
- Add `bin_prot` serializer and deserializer for all exposed types

## 0.7.0

*2016-11-28*

(This release contains breaking changes)

- Fixes CVC EC keys representation (Breaking change)
- Accept a range of rsa and ecdsa oids for CVC keys

## v0.6.1

*2016-11-15*

- Fixes install


## v0.6.0

*2016-11-14*

- Build using `topkg`
- Add `ppx_deriving.runtime` to `META`
- Add support for parsing CVC keys

## v0.5.0

*2016-08-10*

- Explicitly define ocaml version
- Widen dependencies version ranges
- add `ppx_deriving` annotations for `ord` and `yojson` to most of the exposed types in `Asn1` and `Ltpa`

## v0.4.0

*2016-07-25*

- Accept ECDH and ECMQV OIDs for EC keys AlorithmIdentifier
- Add support for encoding/decoding Diffie-Hellman keys
- Use `ppx_deriving_yojson` 3.0

## v0.3.0

*2016-03-10*

- Add converters and compare functions to Asn1.EC
- Split Key_parsers content between Asn1 and Ltpa submodules.
  Breaks compatibility with previous versions.
- Add some tests
- Decode functions now return ('a, string) Result.result.
  Breaks compatibility with previous versions.
- Add LTPA RSA parsers

## v0.2.0

*2016-02-15*

- Add EC keys and parameters parsers
- Compile with `-safe-string`

## v0.1.0

*2015-11-27*

- Initial release

