Mstruct - a mutable interface to Cstruct buffers
------------------------------------------------

Mutable [cstruct](https://github.com/mirage/ocaml-cstruct) buffers.

```ocaml
# #require "mstruct";;
# Log.set_log_level Log.DEBUG;;
# let b = Mstruct.create 9;;
val b : Mstruct.t = <abstr>
# Mstruct.set_string b "hello";;
- : unit = ()
# Mstruct.set_uint32 b 32l;;
- : unit = ()
```

* Docs: <http://docs.mirage.io/mstruct>
