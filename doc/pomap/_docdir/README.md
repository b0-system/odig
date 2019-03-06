## POMAP - Partially Ordered Maps for OCaml

### What is `Pomap`?

The Pomap-library maintains purely functional maps of partially ordered
elements.  Partially ordered maps are similar to partially ordered sets, but
map values for which a partial order relation is defined to some arbitrary
other values.  Here is an example for a partially ordered set to visualize
the idea:

  ![Hasse Diagram of a Partially Ordered Set](http://mmottl.github.io/pomap/hasse.png "Hasse Diagram of a Partially Ordered Set")

Whereas total orders allow you to say whether some element is smaller than,
equal to, or greater than another one, partial orders also allow for a
"don't know"- or "undefined"-case.

Mathematically speaking, the axioms that hold for a partial order relation
are the following:

```text
          x <= x            (reflexivity)
x <= y /\ y <= x -> x = y   (antisymmetry)
x <= y /\ y <= z -> x <= z  (transitivity)
```

Total orders, as usually used for "normal" maps that programmers are acquainted
with, would additionally require the following axiom:

```text
x <= y \/ y <= x  (totality)
```

Whereas a total order allows you to align elements in a linear way to exhibit
this order relation (e.g. `[1; 3; 7; 42]`), partial orders are usually
represented by graphs (so-called Hasse-diagrams).  Here is another example:

```text
                           (89,73)   (93,21)
                              |
                  (91,38)  (57,42)
                     |    /   |
                     |   /    |
                  (44,26)  (25,42)
                      \       /
                       (22,23)
```

The elements of this example partial order structure are pairs of integers.
We say that an element (a pair) is larger than another one if both of
its integers are larger then the respective integers in the other pair.
If both integers are smaller, then the pair is smaller, and if the two pairs
contain equal elements, they are equal.  If none of the above holds e.g. if
the first element of the first pair is smaller than the corresponding one
of the second pair and the second element of the first pair is greater than
its corresponding element of the second pair, then we cannot say that either
of the pairs is greater or smaller, i.e. the order is "unknown" (e.g. pairs
(44,26) and (25,42)).

Lines connecting elements indicate the order of the elements: the greater
element is above the smaller element.  Hasse-diagrams do not display the
order if it is implied by transitivity.  E.g. there is no separate line for
the elements (89,73) and (25,42).  If elements cannot be reached on lines
without reversing direction, then they cannot be compared.  E.g. the pair
(93,21) is incomparable to all others whereas (44,26) cannot be compared to
this latter pair and to (25,42) only.

This library internally represents relations between known elements similar
to Hasse-diagram.  This allows you to easily reason about or quickly manipulate
such structures.

Sounds too mathematical so far? There are many uses for such a library!

#### Application areas

#####  Data-mining

Concept lattices obey rules similar to partial orders and can also be handled
using this library.  E.g., you might have a big e-commerce site with lots
of products.  For marketing purposes it would be extremely useful to know
product baskets that people frequently buy.  This is equivalent to asking
where in a Hasse-diagram such baskets might be placed.

Or imagine you develop a medical system that automatically associates different
mixes of medication with illnesses they effectively treat to support doctors
in deciding on a therapy.  This can all be addressed with concept lattices.

##### Software engineering

Refactoring software to reduce complexity is an important task for large
software projects.  If you have many different components that implement
many different features, you might want to know whether there are groups
of components that make use of specific features in other components.
You could then find out whether the current form of abstraction exactly
meets these dependencies, possibly learning that you should factor out a
set of features in a separate module to reduce overall complexity.

##### Databases

Partial order structures represented by Hasse-diagrams can be used to
optimize database queries on multi-valued attributes by providing better
ways of indexing.

##### General problem-solving

For general problem-solving we often need at least to know whether some
solution is better, equal to, worse or incomparable to another.  Given a
large number of known solutions, the partial order structure containing the
elements can be used to draw conclusions about e.g. whether their particular
form (syntax) implies anything about their position in the partial order
(semantic aspect).

#### What advantages does this particular library offer?

##### Referential transparency

The currently implemented functions all handle the data structure in a purely
functional way.  This allows you to hold several versions of a data structure
in memory while benefiting from structure sharing.  This makes backing out
changes to the data structure efficient and straightforward and also allows
you to use the library safely in a multi-threaded environment.

##### Incremental updates

Some algorithms only perform batch generation of Hasse-diagrams: once the
diagram has been computed, one cannot use such algorithms to add further
elements to it incrementally.  This library can handle incremental updates
(adding and removing of elements) fairly efficiently as required for
online-problems.

##### Efficiency

Both time and memory consumption seem suitable for practical problems,
even not so small ones.  Building up the Hasse-diagram for 1000 elements of
a moderately complex partial order should usually take less than a second
with native code on modern machines.

### Usage

#### API-documentation

Please refer to the API-documentation as programming reference, which
is built during installation with `make doc`.  It can also be found
[online](http://mmottl.github.io/pomap/api/pomap).

#### Specification of the partial order relation

All you need to provide is the function that computes the partial order
relation between two elements.  Take a look at the signature `PARTIAL_ORDER`
in file `lib/pomap_intf.ml`:

```ocaml
module type PARTIAL_ORDER = sig
  type el
  type ord = Unknown | Lower | Equal | Greater
  val compare : el -> el -> ord
end
```

You only have to specify the type of elements of the partially ordered
structure and a comparison function that returns `Unknown` if the elements
are not comparable, `Lower` if the first element is lower than the second,
`Equal` when they are equal and `Greater` if the first element is greater
than the second one.  You can find example implementations of such modules
in directory `examples/hasse/po_examples.ml`.

#### Creating and using partially ordered maps

Given the specification, e.g. `MyPO`, of a partial order relation, we can
now create a map of partially ordered elements like this:

```ocaml
module MyPOMap = Pomap_impl.Make(MyPO)
```

The interface specification `POMAP` in file `lib/pomap_intf.ml` documents in
detail all the functions that can be applied to partially ordered maps and
objects they maintain.  The important aspect is that information is stored in
nodes: you can access the key on which the partial order relation is defined,
the associated data element, the set of indices of successors and the set
of indices of predecessors.  Fresh indices are generated automatically for
new nodes.

Together with accessors to the indices of the bottommost and topmost nodes in
the partially ordered map, this allows for easy navigation in the associated
Hasse-diagram.

#### Rendering Hasse-diagrams using the dot-utility

The Pomap-library also contains modules that allow you to easily render
Hasse-diagrams given some partially ordered map and pretty-printing
functions for elements.  This requires installation of the
[Graphviz](http://www.graphviz.org) package, which supplies the needed
`dot`-utility.  The use of these modules is demonstrated in the distributed
`hasse`-example, which comes with its own README.

### Contact Information and Contributing

Please submit bugs reports, feature requests, contributions and similar to
the [GitHub issue tracker](https://github.com/mmottl/pomap/issues).

Up-to-date information is available at: <https://mmottl.github.io/pomap>
