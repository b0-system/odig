# ocaml-reed-solomon-erasure
[Documentation](https://darrenldl.gitlab.io/ocaml-reed-solomon-erasure/)

OCaml implementation of Reed-Solomon erasure coding

This is a port of [reed-solomon-erasure](https://github.com/darrenldl/reed-solomon-erasure), which is a port of several other libraries.

The SIMD C code is copied from [Nicolas Trangez's Haskell implementation](https://github.com/NicolasT/reedsolomon) with minor modifications.

## Installation
You can install the library via opam
```
opam install reed-solomon-erasure
```

## Example
```OCaml
open Reed_solomon_erasure

let () =
  let r = ReedSolomon.make 3 2 in (* 3 data shards, 2 parity shards *)

  let master_copy = [|"\000\001\002\003";
                      "\004\005\006\007";
                      "\008\009\010\011";
                      "\000\000\000\000"; (* last 2 rows are parity shards *)
                      "\000\000\000\000"|] in

  (* Construct the parity shards *)
  ReedSolomon.encode_str r master_copy;

  (* Make a copy and transform it into option shards arrangement
     for feeding into reconstruct_opt_str *)
  let shards = RS_Shard_utils.shards_to_option_shards_str master_copy in

  (* We can remove up to 2 shards, which may be data or parity shards *)
  shards.(0) <- None;
  shards.(4) <- None;

  (* Try to reconstruct missing shards *)
  ReedSolomon.reconstruct_opt_str r shards;

  (* Convert back to normal shard arrangement *)
  let result = RS_Shard_utils.option_shards_to_shards_str shards in

  assert (ReedSolomon.verify_str r result);
  assert (master_copy = result)
```

## Performance
The encoding performance is shown below

Machine : laptop with `Intel(R) Core(TM) i5-3337U CPU @ 1.80GHz (max 2.70GHz) 2 Cores 4 Threads`

|Configuration| Klaus Post's | reed-solomon-erasure (Rust) | ocaml-reed-solomon-erasure (bigstr) | ... (bytes) | ... (str) |
|---|---|---|---|---|---|
| 10x2x1M | ~7800MB/s | ~4500MB/s | ~3000MB/s | ~1300MB/s | ~1300MB/s |

## Changelog
[Changelog](CHANGELOG.md)

## Contributions
Contributions are welcome. Note that by submitting contributions, you agree to license your work under the same license used by this project(MIT).

## Credits
Many thanks to [Ming](https://github.com/mdchia) for testing the library on macOS platform.

## Notes
#### Code quality review
If you'd like to evaluate the quality of this library, you may find audit comments helpful.

Simply search for "AUDIT" to see the dev notes that are aimed at facilitating code reviews.

## License
#### Nicolas Trangez's Haskell Reed-Solomon implementation
The C files for SIMD operations are copied(with no/minor modifications) from [Nicolas Trangez's Haskell implementation](https://github.com/NicolasT/reedsolomon), and are under the same MIT License as used by NicolasT's project

#### TL;DR
All files are released under the MIT License
