# v0.5.0

* `e63d564` Update change log.
* `2c57d7a` Adapt change log format to topkg workflow
* `56976e3` Create pkg/pkg.ml
* `ba78a8c` Create README.md
* `fa0c900` Add version value to Basics module
* `fe848c8` Replace oasis-based opam workflow by jbuilder-based one
* `73ed7a1` Replace _oasis by jbuild files
* `1b094ee` Fix compatibility with OCaml 4.03.0
* `a46775e` Rename opam file

# v0.4.0

* Make Deferred, Option and Result foldable (`b617fd5`, `a7cc20d`, `86b7e6e`)
* Add an OBFoldable module (also accessible through Basics.Foldable
  (`0241e19`, `c225293`)

# v0.3.0

* `9a31703` Implement Map.traverse and Map.traverse'
* `b70bfe0` Implement an alternative Map.traverse
* `2f1df99` Add a get_ok function to results
* `5ac5e52` Fix versions of some opam deps

# v0.2.0

* create a Traversable module to easily add the traverse function to any monad
* create a Deferred module
* Option and Result now use the Traversable module instead of rewriting the
  the traverse function
* add an opam file
* uppercase files' names

# v0.1.0

First release. It contains:

* interfaces and helpers for the monoid, applicative and monad absractions
* Result, Option and Map modules that implement these interfaces
