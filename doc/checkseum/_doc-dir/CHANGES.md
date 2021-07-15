### v0.3.1 2021-23-02 Paris (France)

- Upgrade `checkseum` to `optint.0.0.5` (@dinosaure, #51)

### v0.3.0 2020-11-03 Paris (France)

- Upgrade C artifacts with MirageOS 3.9 (#50, @dinosaure, @hannesm)
- Fix `esy` installation (#49, @dinosaure, @jordwalke, reported by @Faliszek)

### v0.2.1 2020-06-15 Paris (France)

- Move to dune.2.6.0 (#47)

### v0.2.0 2020-06-03 Paris (France)

- fix cross-compilation with `dune -x windows` (#45, @dinosaure, @pirbo)
- add CRC-24 (#43, @dinosaure, @cfcs)
- factorize C stubs (as digestif)
- avoid clash of names when we use `checkseum.c`
  Any functions are prefixed by `checkseum_`
- fix META file (#39 & #41, @hannesm, @dinosaure)
  A test was added to see if runes (static C libraries) are available for
  MirageOS targets (freestanding & xen)
- provide a binary `checkseum` to _digest_ standard input or file
  `checkseum.checkseum` is available to compute check-sum of standard input
  or file. The tool is used only for debugging.
- clean distribution (#38, @dinosaure)
  `checkseum` depends only on `bigarray-compat`, `base-bytes` & `optint`
- `limits.h` is available on any targets (#37, @dinosaure, @pirbo)

### v0.1.1 2019-09-12 Paris (France)

- Compatibility with mirage+dune (#29, @dinosaure)
- Use `bigarray-compat` (#29, @TheLortex)
- Add constraints with < mirage-runtime.4.0.0

  `checkseum` (as some others packages) must be used with MirageOS 4
  where `checkseum.0.9.0` is a compatibility package with Mirage)S 3

- Replace `STDC` macro check by `STDDEF_H_` to be able to compile (#34, @dinosaure)
  checkseum with +32bit compiler variant (#34, @dinosaure)
- Use a much more simpler implementation of CRC32C to be compatible with large set of targets (#34, @dinosaure)
- Avoid fancy operators in OCaml implementation of CRC32 and CRC32C (#34, @dinosaure)
- Require `optint.0.0.3` at least (#34, @dinosaure)

### v0.1.0 2019-05-16 Paris (France)

- Use experimental feature of variants with `dune` (#25, @dinosaure, review @rgrinberg)
  `checkseum` requires at least `dune.1.9.2`
- Add conflict with `< mirage-xen-posix.3.1.0` packages (#21, @hannesm)
- Provide `unsafe_*` functions (@dinosaure)
- Re-organize C implementation as `digestif` (@dinosaure)
- Remove `#include <stdio.h>` in C implementation (@dinosaure)
- Avoid partial application of functions, optimization (#19, @dinosaure)
- Add ocamlformat support (@dinosaure)
- _cross-compilation_ adjustement about MirageOS backends (#18, @hannesm)

### v0.0.3 2018-10-15 Paris (France)

- _Dunify_ project
- Add CRC32 implementation
- Fixed META file (@g2p)
- Update OPAM file

### v0.0.2 2018-08-23 Paris (France)

- Fix windows support (@nojb)

### v0.0.1 2018-07-06 Paris (France)

- First release of `checkseum`
