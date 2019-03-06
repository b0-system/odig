reedsolomon
===========

[![Build Status](https://travis-ci.org/ujamjar/reedsolomon.svg?branch=master)](https://travis-ci.org/ujamjar/reedsolomon)

Reed-Solomon Error Correction CODEC in OCaml.

The code in the modules Poly, Matrix and Codec is pretty abstract and
not very efficient, however, it implements a few different options
for decoding Reed-Solomon codes (Peterson, Euclid and Berlekamp-Massey)
and both error and erasure correction.

A much faster, error correction only, implementation is
provided in the Iter module (not blazingly fast, but not too bad).

```
open Reedsolomon.Iter

(* code parameters *)
let param = 
  {
    m = 8;
    k = 239;
    t = 8;
    n = 255;
    b = 0;
    prim_poly = 285;
    prim_elt = 2;
  }

(* construct rs codec *)
let rs = Reedsolomon.Iter.init param

(* construct parity from data

   Array.length data = param.k
   Array.length parity = param.t * 2 *)
let () = rs.encode data parity

(* message to send 

   Array.length message = param.n *)
let message = Array.concat [ data; parity ]

(* decode the received and potentially err'd message 

   Array.length received = param.n
   Array.length corrected = param.n *)
let n_corrections = rs.decode received corrected
```

