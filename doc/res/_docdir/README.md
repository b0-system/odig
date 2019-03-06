## RES - Automatically Resizing Contiguous Memory for OCaml

### What is RES?

This OCaml-library consists of a set of modules which implement automatically
resizing (= reallocating) data structures that consume a contiguous part
of memory.  This allows appending and removing of elements to/from arrays
(both boxed and unboxed), strings (buffers), bit strings and weak arrays
while still maintaining fast constant-time access to elements.

There are also functors that allow the generation of similar modules which
use different reallocation strategies.

### Features

  * Fast constant-time access to indexed elements (e.g. in arrays and
    strings) is often a prerequisite for short execution times of programs.

    Still, operations like adding and/or removing elements to/from the
    end of such data structures are often needed.  Unfortunately, having
    both properties at the same time sometimes requires reallocating this
    contiguous part of memory.

    This module does not eliminate this problem, but hides the process of
    reallocation from the user, i.e. it happens automatically.

    Thus, the user is liberated from this bug-attracting (e.g. index errors)
    task.

  * This library allows the user to parameterize allocation strategies at
    runtime.  This is an important feature, because it is impossible for
    any allocation algorithm to perform optimally without having knowledge
    about the user program.

    For example, the programmer might know that a consecutive series of
    operations will alternately add and remove large batches of elements.
    In such a case it would be wise to keep a high reserve of available slots
    in the data structure, because otherwise it will resize very often during
    this procedure which requires a significant amount of time.

    By raising a corresponding threshold in appropriate places at runtime,
    programmers can fine-tune the behavior of e.g. their buffers for optimal
    performance and set this parameter back later to save memory.

  * Because optimal reallocation strategies may be quite complex,
    it was also a design goal to have users supply their own ones (if
    required).

    By using functors users can parameterize these data structures with
    their own reallocation strategies, giving them even more control over
    how and when reallocations are triggered.

  * Users may want to add support for additional low-level implementations
    that require reallocations.  In this case, too, it is fairly easy to
    create new modules by using functors.

  * The library implements a large interface of functions, all of which
    are completely independent of the reallocation strategy and the low-level
    implementation.

    All the interfaces of the corresponding low-level implementations of
    data structures (e.g. array, string) are fully supported and have been
    extended with further functionality.  There is even a new buffer module
    which can be used in every context of the standard one.

  * OCaml makes a distinction between unboxed and boxed arrays.  If the type
    of an array is `float`, the representation will be unboxed in cases in
    which the array is not used in a polymorphic context (native code only).

    To benefit from these much faster representations there are specialized
    versions of automatically resizing arrays in the distribution.

### Usage

The API is fully documented and can be built as HTML using `make doc`.
It is also available [online](http://mmottl.github.io/res/api/res).

The preparameterized modules (default strategy) and the functors for mapping
strategy-implementations to this kind of modules are contained and documented
in file `lib/res.mli`.

For examples of how to use the functors to implement new strategies and/or
low-level representations, take a look at the implementation in `lib/res.ml`.

Their function interface, however, is documented in files `lib/pres_intf.ml`
(for parameterized "low-level" types like e.g. normal arrays) and in
`lib/nopres_intf.ml` (for non-parameterized "low-level" types like e.g. float
arrays, strings (buffers), etc.).

#### Convenience

It should be noted that it is possible to use the standard notation for
accessing elements (e.g. `ar.(42)`) with resizable arrays (and even with
`Buffer`, `Bits`, etc...).  This requires a short explanation of how OCaml
treats such syntactic sugar:

All that OCaml does is that it replaces such syntax with an appropriate
`Array.get` or `Array.set`.  This may be _any_ module that happens to be
bound to this name in the current scope.  The same principle is true for the
`String`-module and the `.[]`-operator.

Thus, the following works:

```ocaml
module Array = Res.Bits
module String = Res.Buffer

let () =
  let ar = Array.empty () in
  Array.add_one ar true;
  print_endline (string_of_bool ar.(0));
  let str = String.empty () in
  String.add_one str 'x';
  print_char str.[0];
  print_newline ()
```

Do not forget that it is even possible to bind modules locally.  Example:

```ocaml
let () =
  let module Array = Res.Array in
  Printf.printf "%d\n" (Array.init 10 (fun x -> x * x)).(7)
```

If you want to change one of your files to make use of resizable arrays
instead of standard ones without much trouble, please read the following:

You may want to "save" the standard `Array`-module and its type for later
access:

```ocaml
module StdArray = Array
type 'a std_array = 'a array
```

Make the resizable implementation (includes the index operators!) available:

```ocaml
open Res
```

Or more explicitly:

```ocaml
module Array = Res.Array
```

Or if you want to use a specific `Array`-implementation:

```ocaml
module Array = Res.Bits
```

Then set the type:

```ocaml
type 'a array = 'a Array.t
```

If you create standard arrays with the built-in syntax, change lines like:

```ocaml
let ar = [| 1; 2; 3; 4 |] in
```

to:

```ocaml
let ar = Array.of_array [| 1; 2; 3; 4 |] in
```

This should allow all of your sources to compile out-of-the-box with the
additional functionality.  In places where you still need the standard
implementation you should have no problems to use the rebound module
and type to do so.

This trick works similarly for the old and the new Buffer-module.  You might
also want to replace the `String`-module in this fashion.  The latter one,
however, supports a number of functions like e.g. `escape`, which are not
available then.

### Contact Information and Contributing

Please submit bugs reports, feature requests, contributions and similar to
the [GitHub issue tracker](https://github.com/mmottl/res/issues).

Up-to-date information is available at: <https://mmottl.github.io/res>
