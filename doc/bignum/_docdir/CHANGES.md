## 113.33.00

- This release improves the slow path of bignum of string. The previous
  version used a split on `'_'` followed by a concat, which allocated a
  bunch of intermediate strings.

## 113.24.00

- Switched to PPX.

- The library used polymorphic compare, rather than `Zarith.Q`'s compare, in a
  few locations. Fixed this.

- Previously stable types in Bignum were defined with unstable types in the scope.
  Fixd this.

- Update to zarith-1.4

- `Bignum.of_string` needs to handle different formats for its input. The
  previous version of the code was trying to parse the common format
  (floats), and in case of failure, was attempting to use a different
  format (based on the error). This resulted in the string being parsed
  twice in some cases.

  This version is a complete rewriting of `of_string` to do the parsing
  in one step. The new code for `to_string` encode an automaton and
  remembers the positions of the various elements of the string
  (depending on the format).

  This feature uses a function which has been upstreamed in the new
  version of ZArith (1.4) which is a variant of the `Zarith.of_string`
  function to work with substrings. This variant alone is responsible
  for a big part of the performance improvement.

  Summary of benchmarks
  -----------------

  The new version of the code performs better than the original one in
  all cases. The performance improvement are variable depending on the
  micro benchmark. See below.

  Follow ups
  ----------

  We also tried to implement the lexing engine using OCamllex.
  This makes for a much more concise description, but the
  performance are significantly lower. OCamllex produces code which
  allocates some table and some state, which is avoided in the hand
  written code. Also, it will allocate the sub strings matched.


  Benchmark results
  -----------------

  New version (patch for ZArith + of\_substring, reimplementation of of\_string)

  ┌─────────────────────────────────────────────────────────────────────┬──────────────┬───────────┬──────────┬──────────┬────────────┐
  │ Name                                                                │     Time/Run │   mWd/Run │ mjWd/Run │ Prom/Run │ Percentage │
  ├─────────────────────────────────────────────────────────────────────┼──────────────┼───────────┼──────────┼──────────┼────────────┤
  │ `bigint\_bench.ml` random                                            │  48\_381.13ns │ 7\_166.00w │    1.24w │    1.24w │     45.12% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_self                             │     293.96ns │    72.00w │          │          │      0.27% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_other                            │     807.62ns │   124.00w │          │          │      0.75% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_self                             │     353.98ns │    91.00w │          │          │      0.33% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_other                            │     783.78ns │   128.00w │          │          │      0.73% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (decimal)    │  14\_415.44ns │   475.00w │          │          │     13.44% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (scientific) │  61\_363.80ns │ 3\_929.00w │          │          │     57.23% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (fraction)   │  24\_957.02ns │   303.00w │          │          │     23.28% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (decimal)    │  15\_867.52ns │ 1\_523.00w │          │          │     14.80% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (scientific) │  33\_345.31ns │ 4\_206.00w │          │          │     31.10% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (fraction)   │  31\_770.26ns │ 3\_779.00w │          │          │     29.63% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (decimal)          │   9\_726.82ns │   380.00w │          │          │      9.07% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (scientific)       │  28\_141.40ns │ 2\_059.00w │          │          │     26.25% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (fraction)         │  70\_436.16ns │ 5\_541.00w │          │          │     65.69% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (decimal)          │  27\_000.73ns │ 1\_994.00w │          │          │     25.18% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (scientific)       │  66\_057.63ns │ 6\_217.00w │          │          │     61.61% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (fraction)         │ 107\_219.89ns │ 8\_097.00w │          │          │    100.00% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip compact                  │   5\_997.81ns │   581.00w │          │          │      5.59% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip classic                  │  18\_522.20ns │   779.00w │          │          │     17.27% │
  │ `bignum\_bench.ml:round` round\_decimal:0                             │   8\_479.49ns │   463.00w │          │          │      7.91% │
  │ `bignum\_bench.ml:round` round\_decimal:3                             │  24\_621.71ns │ 2\_115.00w │          │          │     22.96% │
  │ `bignum\_bench.ml:round` round\_decimal:6                             │  26\_896.35ns │ 2\_437.00w │          │          │     25.09% │
  │ `bignum\_bench.ml:round` round\_decimal:9                             │  29\_428.19ns │ 2\_730.00w │          │          │     27.45% │
  │ `bignum\_bench.ml:round` round                                       │   8\_452.31ns │   459.00w │          │          │      7.88% │
  └─────────────────────────────────────────────────────────────────────┴──────────────┴───────────┴──────────┴──────────┴────────────┘

  Original version

  ┌─────────────────────────────────────────────────────────────────────┬──────────────┬───────────┬──────────┬──────────┬────────────┐
  │ Name                                                                │     Time/Run │   mWd/Run │ mjWd/Run │ Prom/Run │ Percentage │
  ├─────────────────────────────────────────────────────────────────────┼──────────────┼───────────┼──────────┼──────────┼────────────┤
  │ `bigint\_bench.ml` random                                            │  51\_218.04ns │ 7\_166.00w │    1.25w │    1.25w │     43.26% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_self                             │     336.84ns │    72.00w │          │          │      0.28% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_other                            │     837.73ns │   124.00w │          │          │      0.71% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_self                             │     411.03ns │    91.00w │          │          │      0.35% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_other                            │     808.03ns │   128.00w │          │          │      0.68% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (decimal)    │  29\_650.60ns │ 2\_415.00w │          │          │     25.04% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (scientific) │  92\_495.93ns │ 6\_465.00w │          │          │     78.12% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (fraction)   │  39\_482.77ns │ 2\_060.00w │          │          │     33.35% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (decimal)    │  16\_195.93ns │ 1\_523.00w │          │          │     13.68% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (scientific) │  34\_227.78ns │ 4\_059.00w │          │          │     28.91% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (fraction)   │  32\_856.17ns │ 3\_779.00w │          │          │     27.75% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (decimal)          │  19\_745.71ns │ 2\_149.00w │          │          │     16.68% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (scientific)       │  51\_024.99ns │ 3\_853.00w │          │          │     43.09% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (fraction)         │  88\_884.15ns │ 7\_819.00w │          │          │     75.07% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (decimal)          │  32\_812.27ns │ 2\_498.00w │          │          │     27.71% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (scientific)       │  77\_518.77ns │ 6\_369.00w │          │          │     65.47% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (fraction)         │ 118\_402.78ns │ 8\_907.00w │          │          │    100.00% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip compact                  │   8\_947.02ns │   371.00w │          │          │      7.56% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip classic                  │  22\_799.74ns │ 1\_039.00w │          │          │     19.26% │
  │ `bignum\_bench.ml:round` round\_decimal:0                             │   8\_176.74ns │   463.00w │          │          │      6.91% │
  │ `bignum\_bench.ml:round` round\_decimal:3                             │  25\_798.77ns │ 2\_115.00w │          │          │     21.79% │
  │ `bignum\_bench.ml:round` round\_decimal:6                             │  28\_561.23ns │ 2\_437.00w │          │          │     24.12% │
  │ `bignum\_bench.ml:round` round\_decimal:9                             │  30\_861.38ns │ 2\_730.00w │          │          │     26.06% │
  │ `bignum\_bench.ml:round` round                                       │   8\_237.26ns │   459.00w │          │          │      6.96% │
  └─────────────────────────────────────────────────────────────────────┴──────────────┴───────────┴──────────┴──────────┴────────────┘

  Tentative version using OCamllex

  ┌─────────────────────────────────────────────────────────────────────┬──────────────┬────────────┬──────────┬──────────┬────────────┐
  │ Name                                                                │     Time/Run │    mWd/Run │ mjWd/Run │ Prom/Run │ Percentage │
  ├─────────────────────────────────────────────────────────────────────┼──────────────┼────────────┼──────────┼──────────┼────────────┤
  │ `bigint\_bench.ml` random                                            │  48\_164.21ns │  7\_166.00w │    1.25w │    1.25w │     39.99% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_self                             │     285.84ns │     72.00w │          │          │      0.24% │
  │ `bigint\_bench.ml:vs. Big\_int` plus\_other                            │     768.12ns │    124.00w │          │          │      0.64% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_self                             │     343.14ns │     91.00w │          │          │      0.28% │
  │ `bigint\_bench.ml:vs. Big\_int` mult\_other                            │     780.00ns │    128.00w │          │          │      0.65% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (decimal)    │  26\_931.12ns │  3\_108.00w │          │          │     22.36% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (scientific) │  79\_750.28ns │  6\_599.00w │    0.11w │    0.11w │     66.21% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` of\_string (fraction)   │  34\_988.94ns │  4\_300.00w │          │          │     29.05% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (decimal)    │  15\_958.17ns │  1\_523.00w │          │          │     13.25% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (scientific) │  32\_495.25ns │  4\_059.00w │          │          │     26.98% │
  │ `bignum\_bench.ml:Bignum of\_string/to\_string` to\_string (fraction)   │  31\_802.75ns │  3\_779.00w │          │          │     26.40% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (decimal)          │  18\_742.81ns │  2\_924.00w │          │          │     15.56% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (scientific)       │  45\_282.09ns │  4\_622.00w │          │          │     37.60% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` of\_sexp (fraction)         │  86\_907.83ns │  8\_777.00w │    0.15w │    0.15w │     72.16% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (decimal)          │  35\_727.73ns │  4\_493.00w │          │          │     29.66% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (scientific)       │  82\_247.61ns │  8\_273.00w │    0.13w │    0.13w │     68.29% │
  │ `bignum\_bench.ml:Bignum of\_sexp/to\_sexp` to\_sexp (fraction)         │ 120\_445.25ns │ 10\_688.00w │    0.12w │    0.12w │    100.00% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip compact                  │   6\_734.49ns │    371.00w │          │          │      5.59% │
  │ `bignum\_bench.ml:Bignum binprot` roundtrip classic                  │  21\_773.79ns │  1\_890.00w │          │          │     18.08% │
  │ `bignum\_bench.ml:round` round\_decimal:0                             │   8\_306.45ns │    463.00w │          │          │      6.90% │
  │ `bignum\_bench.ml:round` round\_decimal:3                             │  24\_714.96ns │  2\_115.00w │          │          │     20.52% │
  │ `bignum\_bench.ml:round` round\_decimal:6                             │  26\_894.27ns │  2\_437.00w │          │          │     22.33% │
  │ `bignum\_bench.ml:round` round\_decimal:9                             │  29\_343.81ns │  2\_730.00w │          │          │     24.36% │
  │ `bignum\_bench.ml:round` round                                       │   8\_296.05ns │    459.00w │          │          │      6.89% │
  └─────────────────────────────────────────────────────────────────────┴──────────────┴────────────┴──────────┴──────────┴────────────┘

## 113.00.00

- Fixed a bug in the =Zarith= library's `to_float` function.

    These fixes first introduce tests from the base distribution, and then
    backport a bugfix to the handling of to_float.

## 112.35.00

- Upgraded from Zarith 1.2 to 1.3.
- Removed dependence on `Big_int`.

## 112.24.00

- Fixed exception raised by `Bignum.sexp_of_t` when the denominator is zero.

## 112.17.00

- Added `Bigint.random` function, which produces a uniformly
  distributed value.

## 112.06.00

- Added functions to round from `Bignum.t` to `Bigint.t`, and to convert
  `Bigint.t` into `Bignum.t`.

## 112.01.00

- Added `Bignum.Bigint` module, with arbitrary-precision integers
  based on `Zarith`, which is significantly faster than the
  `Num.Big_int` library.

## 111.17.00

- Improved the performance of binprot deserialization by removing the
  allocation of an intermediate type.

## 111.13.00

- Eliminated the dependence of `Bignum` on `Re2`, and reduced dependence
  from `Core` to `Core_kernel`.
- Extended the rounding interface to bring it in line with int and float
  rounding.
- Improved the performance of `Bignum`'s binprot.

    `Bignum`'s binprot had been to just binprot the decimal string
    representation.  This is both slow to do and unnecessarily big in
    the majority of cases.  Did something better in the majority of
    cases and fell back to this representation in the exceptional case.

        $ ./inline_benchmarks_runner
        Estimated testing time 20s (2 benchmarks x 10s). Change using -quota SECS.

    | Name                                                 | Time/Run |   mWd/Run | Percentage |
    |------------------------------------------------------|----------|-----------|------------|
    | bignum0.ml:Stable:Bignum binprot roundtrip compact   |   7.87us |   490.00w |     32.88% |
    | bignum0.ml:Stable:Bignum binprot roundtrip classic   |  23.94us | 1_079.00w |    100.00% |
