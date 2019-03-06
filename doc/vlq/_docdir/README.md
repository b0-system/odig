# ocaml-vlq

A simple library for encoding [variable-length quantities](https://en.wikipedia.org/wiki/Variable-length_quantity).

It currently supports writing a base64-encoded integer to a `Buffer`. Patches implementing other forms of encoding are welcome!


## Example

```ocaml
let buf = Buffer.create 10 in
Vlq.Base64.encode buf 123456789;
Buffer.contents buf (* "qxmvrH" *)

let stream = Stream.of_string "qxmvrH" in
Vlq.Base64.decode stream (* 123456789 *)
```

This encoding can be used to generate JavaScript sourcemaps.


## License

ocaml-vlq is MIT licensed, as found in the LICENSE file.
