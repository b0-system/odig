# OCaml-RFC7748

Elliptic curves for cryptographic purposes, based on [RFC 7748](https://tools.ietf.org/html/rfc7748).

## Usage

The [API](src/rfc7748.mli) contains documentation. Example use: 

```ocaml
open Rfc7748

let _ =
  let priv = X25519.private_key_of_string
      "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4" in
  let pub = X25519.public_key_of_string
      "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c" in
  X25519.scale priv pub
  |> X25519.string_of_public_key
  |> Printf.printf "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552\n == \n%s"
```

## License

BSD 2-clause, see [license](LICENSE).
