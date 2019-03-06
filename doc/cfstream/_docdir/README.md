CFStream - Core-friendly extension of OCaml's Stream data structure  

DESCRIPTION
===========
Streams represent a sequence of data items, which can be operated on
one at a time. Thus, it is possible to operate on a large sequence of
items without loading them into memory.

This library extends the [standard library's Stream
module](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Stream.html)
with several practical functions. CFStream stands for "Core-friendly
Stream". The library is so named because the API follows the [Core
standard
library's](https://ocaml.janestreet.com/ocaml-core/latest/doc/) style,
e.g. labeled arguments are used. It is also inspired by [Batteries's
Enum
module](http://ocaml-batteries-team.github.com/batteries-included/hdoc2/BatEnum.html).

The implementation is useful for beginners and simple scripts. Robust
high-performance software should instead use
[Lwt](http://ocsigen.org/lwt/) or
[Async](https://ocaml.janestreet.com/ocaml-core/latest/doc/async_core/index.html).

LICENSE
=======
The CFStream library is distributed according to the LGPL + linking
exception terms as defined in the LICENSE file included with the
source code.

CONTACT
=======
The library is managed under the Biocaml project, though it is in no way
specific to Biology.  
Website: <http://biocaml.org>  
Mailing List: <http://groups.google.com/group/biocaml>  
