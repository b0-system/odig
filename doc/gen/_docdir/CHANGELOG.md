# Changelog

# 0.5

- fix small problem with safe-string
- move to safe-string, for compatibility with 4.06.0
- add optimize() flag to `_tags`
- rename parameter of `int_range` from `by` to `step`
- add `?(by=1)` to `int_range`

# 0.4

- update `GenLabels` with missing functions
- add `Gen.peek_n`
- add `Gen.peek`
- add first draft of `GenM`, an overlay for iterating over monadic values.
  this module is experimental as of now.
- cleanup:
  * more tests
  * move all tests to gen.ml using qtest
  * merge benchmarks into a single file
  * add ocp-indent file, update header, reindent files
  * move code to src/

# 0.3

- add `Gen.return`
- fix overflow in `Gen.flat_map`; add regression test
- opam: depend on ocamlbuild
- add functions `Gen.{lines,unlines}`
- add `Gen.Restart.of_gen` as a convenient alias to `persistent_lazy`
- add `Gen.IO.{with_lines, write_lines}`
- update benchmarks to use Benchmark.Tree

# 0.2.4

- `GenLabels` module
- `fold_while` function
- `fold_map` implementation, deprecating `scan`
- updated doc to make clear that combinators consume their generator argument
- add missing @since; expose infix operators

# 0.2.3

- updated .mli to replace "enum" with "gen"
- `Gen.persistent_lazy` now exposes caching parameters related to `GenMList.of_gen_lazy`
- give control over buffering in `GenMList.of_gen_lazy`
- move some code to new modules GenClone and GenMList
- add lwt and async style infix map operators
- Gen.IO
- `to_string`, `of_string`, `to_buffer`
- opam file
- add `permutations_heap` for array-based permutations; add a corresponding benchmark to compare
- license file

# 0.2.2

- do not depend on qtest
- better combinatorics (`permutations`, `power_set`, `combinations`)
-` Gen.{permutations,power_set,combinations}`
- `Gen.unfold_scan`
- put Gen.S into a new module, `Gen_intf`
- `Gen.persistent_lazy` implemented
- .merlin files

## 0.2.1

- added many tests using Qtest; fixed 2 bugs
- simpler and more efficient unrolled list
- unrolled list for Gen.persistent (much better on big generators)

## 0.2

- changed `camlCase` to `this_case`
- `take_nth` combinator

note: `git log --no-merges previous_version..HEAD --pretty=%s`

