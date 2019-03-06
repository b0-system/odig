Interface'
==========

## Abstract interface for common design patterns

Interface' *(pron. Interface Prime)* provides an abstraction for common design patterns (e.g. monads) which can be implemented by your favourite libraries (e.g. lwt and async) to reduce the coupling between your code and your dependencies.

**Whats the point?**
I've seen in many libraries the redefininition the same standard functions for monadic operations, e.g. bind/(>>=), fmap/(>|=)/(>>|). To simplify this NxN problem, Interface' aims to act as an abstraction over common design patterns like monads to allow a bit more flexibility between the code you write and the libraries you use.
