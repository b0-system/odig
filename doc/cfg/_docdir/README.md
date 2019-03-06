## CFG - Manipulation of Context-Free Grammars

### What is CFG?

This [OCaml](http://www.ocaml.org)-library consists of a set of modules which
implement functions for analyzing and manipulating context-free grammars
(CFGs) in a purely functional way.

The core-module `cfg_impl.ml` contains a functor which allows the
parameterization of the main transformation functions with arbitrary grammar
entities (terminals, nonterminals, productions).  See the interface in
`cfg_intf.ml` and the BNF-example.

Thus, you may use this module for any kind of symbolic system that
is equivalent to a context-free grammar.  This includes, for example,
specifications of algebraic data types, which are isomorphic.

### Using CFG

Besides building up grammars with the single function `add_prod`, some
powerful functions allow you to construct new grammars from old ones: `union`,
`diff`, `inter`.  These functions behave somewhat like their set counterparts.
E.g. `inter` will generate the intersection of all grammar entities (common
nonterminals and their common productions).

Further manipulation functions exist for:

  * Pruning unproductive productions and nonterminals: they contain
    references to nonexistent symbols.

  * Pruning nonlive entities: such symbols and productions only exist
    in cyclic derivations from which there is no escape.

  * Pruning unreachable entities: such symbols and productions cannot be
    reached from the start symbol.

  * Generating a 'sane' grammar: combines the above steps.  In such
    grammars each entity is useful.

Functions for getting information on grammars:

  * Calculating the minimum number of derivations necessary to derive
    nonterminals and productions.  This step is performed during pruning
    of nonlive symbols, because this process allows the easy collection of
    this information.

  * Because the implementation is purely functional, the library can
    safely and efficiently export its internal representation without copying.

Due to the applicative nature of the library, which allows a lot of sharing
in memory (persistence), it should be useful for handling large grammars
efficiently.

### Documentation of Functions

For details see the API documentation in `cfg_intf.ml` or consult the latest
[online API documentation](http://mmottl.github.io/cfg/api/cfg).

### BNF-Example

The example in `examples/bnf` uses CFGs in traditional BNF-notation, which
represents terminals and nonterminals as plain strings.  It reads in a grammar
specification from `stdin` and prints information about the grammar.  Here is
an example invocation (from top directory in the distribution after building):

```sh
bnf.native < examples/bnf/test.bnf
```

You cannot have several productions that contain the same terminals and
nonterminals in the same order, because this BNF-example uses the unit-type
for tagging productions.  This does not allow for differences other than of
syntactical nature.

Thus, if you want to be able to distinguish between two productions which
are otherwise structurally equivalent, just parameterize the CFG-module so
that productions receive an additional tag to make them unequal.

This allows you, for example, to use the library for doing transformations on
grammars for abstract syntax, where productions carry additional information
concerning static semantics (e.g. attributes).  Two syntactically identical
productions may have different semantics then and will not be treated the same.

### Contact Information and Contributing

Please submit bugs reports, feature requests, contributions and similar to
the [GitHub issue tracker](https://github.com/mmottl/cfg/issues).

Up-to-date information is available at: <https://mmottl.github.io/cfg>
