## 1.0.2
- Fixed benchmark data
  - Previously used MB=10^6 bytes while I should have used MB=2^20 bytes
  - Table in README has been updated accordingly
    - The data is obtained by measuring again with the corrected `benchmark/bench.ml` code
- Minor doc fix
- Migrated from jbuilder to dune
- Improved performance of pure OCaml Galois code
  - This means in pure OCaml mode, the library has significantly improved performance compared to previous versions

## 1.0.1
- Fixed misuse of `==` operator in `.ml` files
  - Replaced with `=` operator

## 1.0.0
- Base version
